# Outline
1. Read Laravel intro
	1. https://laravel.com/learn/getting-started-with-laravel
2. Laravel API
	1. Configure request manager(app/Http/Request)
	2. Configure controller(app/Http/Controllers)
	3. Configure routes(routes/api.php)
3. Flutter API
	1. Configure API class for module(/lib/api/)
	2. Configure data class to store and map data(/lib/models/)
	3. Configure `async` function to deal with form(/lib/widgets/<inside)

Flow of form data
1. input into form 
2. convert into json 
3. submit HTTP POST to backend server 
4. backend server receives HTTP request 
5. Laravel checks `api.php` for route 
6. authenticate(not used for debugging now) 
7. pass JSON to corresponding controller function 
8. parse data 
9. make query

---
# Laravel
## Request Management
Use 
```
php artisan make:request <filename>
```
- Functions: 
	- `authorize()`: bool, logic to determine if user is authorized to make request
		- set to true for debugging
	- `rules()`: returns array that stores validation rules
		- uses named arrays with key => value
		- values is another array with rules like 'required', 'string', min max length
	- `messages()`: error messages
		- can leave blank for now
## Controller
Created together with migration file using 
```
php artisan make:model <filename> -rmc
```
Can also created individually with
```
php artisan make:controller <filename>
```

`create()` 
- used to create form
- show form to get input data
- since form dealt with Flutter, ignore

`store()`
- handles POST data
- actual function that inserts to database
## Configure Routes
Route syntax for post used
```
Route::post('uri', [<ControllerClassName>::class, 'function to send data to']);
```

---
# Flutter
- For intro on async operations, see [[Async Operations]]
## API class
- Set API url of backend services, for XAMPP, use
	- `http://localhost:8000/api/<your api file name>`
	- IP address can also be used, but check `.env` file just in case
- Write API function 
	- one method for one CRUD operation
	- encode data to JSON with `jsonEncode(Map<>)`
	- send HTTP request with `await http.post()`
		- remember to import `http` dependencies
	- remaining is error handling
## Data class
- Store your object in a designated class
- Put encoding and decoding functions in here
## Form Submission in UI
- Add function for submission
- Call API method, passing data into method
- Set submission button `onPressed` action to call submit function
---
# Possible Issues
- **REMEMBER TO**  `php artisan serve`
	- If multiple ports not working, see Laravel Herd
- **REMEMBER TO** turn  on SQL server 
	- If SQL server on XAMPP in error, check netstat and turn off program in task manager
- If using XAMPP remember to turn on APACHE
- Check `.env` for database info
	- Database Name
	- Database URL and port
	- Database Used(sql, sqlite, postgres, etc.)
- If using Laravel Herd
	- DO NOT TURN ON XAMPP APACHE
   - NO need to `php artisan serve`, just ensure Herd is on
   - Put `/backend_services` into Herd paths
	- YOU STILL NEED TO TURN ON SQL ON XAMPP
	- Install and include phpmyadmin into your laravel HERD projects
	- Change phpmyadmin configuration to allow no password
	- **Use Herd site URL** instead of `localhost`
	- REMEMBER TO CHANGE apiURL in FLUTTER TOO
- Put post route of `api.php` outside of auth route for debugging
- Check dependencies and include correct library(especially for Laravel)
- Check debug output for flutter
- Check Laravel logs
	- Powershell Command:`Get-Content storage/logs/laravel.log -Wait`
	- Remember to cd into directory
