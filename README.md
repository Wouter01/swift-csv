# swift-csv
This package provides iterators to parse CSV files from Swift, with a focus on performance and efficiency. 
The provided file is read in a streaming way, and is not loaded in memory as a whole. This reduces memory usages drastically, especially for large files.

Three AsyncSequences are provided: `AsyncCodableCSVIterator`, `AsyncRawCSVIterator` and `AsyncRawAsDictCSVIterator`.

### Features
- Asynchronous reading of CSV files, line by line.
- Decode using Codable types.
- Process each row manually as a list of strings or a key-value dictionary.
- Support for files with or without headers.
- Error handling, option to skip invalid rows.
- Support for custom delimiters, escape characters and file encodings.
- Support for local and remote CSV files.

### Examples
Parse the CSV file at once, decode using `Codable` types:
```swift
let ratings: [Rating] = try await Task.detached {
    try await AsyncCodableCSVIterator(url: ratingsURL)
        .reduce(into: []) { $0.append($1) }
}.value
```

Parse the CSV file row by row, get list of strings for each row:
```swift
let reader = try await AsyncRawCSVIterator(url: ratingsURL, hasHeaders: true, skipInvalidRows: false)
for try await row in reader {
    // process...
}
```

Parse the CSV file row by row, get a dict of key-value strings for each row:
```swift
let reader = try await AsyncRawAsDictCSVIterator(url: ratingsURL)
for try await row in reader {
    // process...
}
```

### Notes about Performance
One of the goals of this package is to provide a fast and efficient way to parse CSV files, while still using regular Swift.
This isn't always an easy task, as one can quickly fall into performance traps. Making small changes to how the API is used can drastically improve the performance of your app:

- When possible, do **NOT** use the API on the Main Actor. Internally, the API is using [`URL.resourceBytes`](https://developer.apple.com/documentation/foundation/url/3767316-resourcebytes) which runs off the Main Actor. If the iterator is used on the main actor, a context switch will happen for **each** row, making the iteration much slower. In my own testings, this made the parsing of a file 6 times slower. Instead, use a Task.detached when iterating over the file. When parsing, no context switches will happen.
```swift
let ratings: [Rating] = try await Task.detached {
  try await AsyncCodableCSVIterator(url: ratingsURL)
      .reduce(into: []) { $0.append($1) }
  }
}.value
```
- When decoding with `AsyncCodableCSVIterator`, try using Int-based CodingKeys instead of String-based CodingKeys. This shouldn't be a problem, as a CSV file contains ordered data. Decoding the data is much faster using indexes rather than a dictionary lookup. In tests, using Int-based CodingKeys results in a approx. 30% faster decoding.
```swift
struct Rating: Codable {
  let id: String,
      movieID: String,
      ratingValue: Int,
      userID: String

  enum CodingKeys: Int, CodingKey {
      case id
      case movieID
      case ratingValue
      case userID
  }
}
```
### Benchmarks
Some benchmarks were performed to evaluate the performance of the API.
The benchmark will parse a 616MB CSV file with 11078167 rows and 4 columns. The AsyncCodableCSVIterator runs will decode the data into the `Rating` type. The other will not process the strings any further.

|                          | Swift 5.10 | Swift 6.0 (2024-05-26) |
|----------|----------|----------|
| AsyncRawCSVIterator    | 6.88s   | 5.68s  |
| AsyncCodableCSVIterator, Int CodingKeys    |  10.41s  | 7.27s   |
| AsyncRawAsDictCSVIterator    | 10.66s   | 9.14s   |
| AsyncCodableCSVIterator, String CodingKeys   | 14.92s   | 11.14s   |
