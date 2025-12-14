# Login Logout Controllers
```
php artisan make:controller Auth/Login --invokable
php artisan make:controller Auth/Logout --invokable
```

## Login
```

<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class Login extends Controller
{
    public function __invoke(Request $request)
    {
        // Validate the input
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // Attempt to log in
        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            // Regenerate session for security
            $request->session()->regenerate();

            // Redirect to intended page or home
            return redirect()->intended('/')->with('success', 'Welcome back!');
        }

        // If login fails, redirect back with error
        return back()
            ->withErrors(['email' => 'The provided credentials do not match our records.'])
            ->onlyInput('email');
    }
}
```
`(Auth::attempt($credentials, $request->boolean('remember')))`
- If `$request->boolean('remember')` is true,
	- create and store standard short-lived session cookie
	- generate remember me token in stored in user's record in database
		- sends corresponding long-lived cookie to user's browser
- `Auth::attempt()`
	- Takes credential array and searches database for user whose columns match all identifier fields in `$credentials` except for password
	- Compares hashed and raw passwords
	- If verification succeeds, log user in
## Logout
```

<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class Logout extends Controller
{
    public function __invoke(Request $request)
    {
        Auth::logout();

        // Invalidate session
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/')->with('success', 'You have been logged out.');
    }
}
```
`Auth::logout()`: package to 
- regenerate session
- invalidate session
- regenerate new token so that users not logged in have fresh tokens
# Add Login/Logout Routes
`routes/web.php`
```
use App\Http\Controllers\Auth\Login;
use App\Http\Controllers\Auth\Logout;

// Login routes
Route::view('/login', 'auth.login')
    ->middleware('guest')
    ->name('login');

Route::post('/login', Login::class)
    ->middleware('guest');

// Logout route
Route::post('/logout', Logout::class)
    ->middleware('auth')
    ->name('logout');
```
- If using a named route, use named routes for all
> Laravel automatically redirects to `/login` when unauthenticated user tries to access protected route
# Laravel Security Features
- Protection from
	- session hijacking
	- CSRF attacks
	- Password exposure
	- Timing attacks
	- Session fixation
