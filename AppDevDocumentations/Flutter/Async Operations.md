# Slight Intro
- **Async Operations**: tasks executed independently of main program flow
	- Allows program to run without waiting for long task to complete
- e.g. 
	- Fetching data over Internet
	- Read file
	- Wait for timer
## async
- Keyword
- Signals that function is async function
- async function must be `Future` return type
## await
- Keyword
- Only usable in async functions
	- **aka requires `async` in function header**
- Gemini:
	- When the Dart runtime sees `await` before a `Future` (like `http.post()`), it performs these two steps:
		1. **Suspension:** It **suspends** the execution of the function (`_submitForm`) right at that point.
		2. **Resumption:** It allows the rest of the application (the UI thread) to continue running, drawing frames, and responding to user input. When the network operation finally completes and returns the `Response` object, the function **resumes** execution on the very next line of code.
# Future::class
- Represents potential value/error available in future
- Returned by all async operations
- Promise to deliver result later
## Future\<type\>
- \<type> : specifies type of value `Future` will return upon successful completion
- `<void>`: function purpose is to perform action, but does not return value
- `<string>`: function will return `String` upon completion


# `jsonEncode()`
- Converts a Dart object(typically `Map` or `List`) to single, standardized JSON string
- **Keys become JSON keys:** All Map keys (which must be Strings in the Dart input) are wrapped in double quotes in the output.
    
- **Values are converted:**
    - Dart `String`s become JSON strings (wrapped in double quotes).
    - Dart `int`s and `double`s become JSON numbers.
    - Dart `true`/`false` become JSON `true`/`false`.
    - Dart `null` becomes JSON `null`.

- **Required as part of HTTP request**
# `http.post()`
- Initiates HTTP POST request to set URL
- Arguments
	- `Uri.parse(url)`: destination URL
	- body: typically the JSON string
	- headers: optional field for metadata
- **Return Type:** `Future<Response>`
# `mounted`
- `boolean`
	- true if widget is existing/active
- Used in `await` to ensure modification only done on alive widgets