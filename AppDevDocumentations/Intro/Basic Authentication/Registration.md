```
<form method="POST" action="/register">
	@csrf
	<!-- Name -->
	<label class="floating-label mb-6">
		<input type="text"
			   name="name"
			   placeholder="John Doe"
			   value="{{ old('name') }}"
			   class="input input-bordered @error('name') input-error @enderror"
			   required>
		<span>Name</span>
	</label>
	@error('name')
		<div class="label -mt-4 mb-2">
			<span class="label-text-alt text-error">{{ $message }}</span>
		</div>
	@enderror

	<!-- Email -->
	<label class="floating-label mb-6">
		<input type="email"
			   name="email"
			   placeholder="[mail@example.com](<mailto:mail@example.com>)"
			   value="{{ old('email') }}"
			   class="input input-bordered @error('email') input-error @enderror"
			   required>
		<span>Email</span>
	</label>
	@error('email')
		<div class="label -mt-4 mb-2">
			<span class="label-text-alt text-error">{{ $message }}</span>
		</div>
	@enderror

	<!-- Password -->
	<label class="floating-label mb-6">
		<input type="password"
			   name="password"
			   placeholder="••••••••"
			   class="input input-bordered @error('password') input-error @enderror"
			   required>
		<span>Password</span>
	</label>
	@error('password')
		<div class="label -mt-4 mb-2">
			<span class="label-text-alt text-error">{{ $message }}</span>
		</div>
	@enderror

	<!-- Password Confirmation -->
	<label class="floating-label mb-6">
		<input type="password"
			   name="password_confirmation"
			   placeholder="••••••••"
			   class="input input-bordered"
			   required>
		<span>Confirm Password</span>
	</label>

	<!-- Submit Button -->
	<div class="form-control mt-8">
		<button type="submit" class="btn btn-primary btn-sm w-full">
			Register
		</button>
	</div>
</form>
```

# Registration Controller
- Laravel recommendation: use single action controllers(invokable controllers) for actions that don't fit standard resource pattern
	- Only one method per controller
```
php artisan make:controller Auth/Register --invokable
```
- Creates single action controller in namespace `/Http/Controllers/Auth/Register.php`
```

<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class Register extends Controller
{
    public function __invoke(Request $request)
    {
        // Validate the input
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // Create the user
        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        // Log them in
        Auth::login($user);

        // Redirect to home
        return redirect('/')->with('success', 'Welcome to Chirper!');
    }
}
```
# Add Routes
`routes/web.php`
```
use App\Http\Controllers\Auth\Register;

// Registration routes
//for get
Route::view('/register', 'auth.register')
    ->middleware('guest')
    ->name('register');

//for post
Route::post('/register', Register::class)
    ->middleware('guest');
```
- Ensure routes are accessible by anyone even if not logged in

- Can use `Route::view()` directly for GET
- For POST route, pas invokable controller class

- Middleware `guest` ensures only non-authenticated users can access routes
- `->name('register')`: named route
- Benefit of **Named Routes**
	- When defining named route, can create alias or permanent identifier for route functionality independent of actual URL path

| Scenario       | Code                                                                   | How it's referenced                                                                                           | Advantage   |
| -------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ----------- |
| Original Route | `Route::view('/register', '...')->name('register');`                   | You reference the route everywhere using its name: `route('register')`.                                       | Decoupling  |
| Path Change    | You change the URI to: `Route::view('/new', '...')->name('register');` | All your links, redirects, and forms that use `route('register') `automatically point to the new `/new` path. | Maintenance |
# Protect Routes
- Ensure only authenticated users can create chirps
```
Route::get('/', [ChirpController::class, 'index']);

// Protected routes
Route::middleware('auth')->group(function () {
    Route::post('/chirps', [ChirpController::class, 'store']);
    Route::get('/chirps/{chirp}/edit', [ChirpController::class, 'edit']);
    Route::put('/chirps/{chirp}', [ChirpController::class, 'update']);
    Route::delete('/chirps/{chirp}', [ChirpController::class, 'destroy']);
});
```
# Update Controller
```1

public function store(Request $request)
{
    $validated = $request->validate([
        'message' => 'required|string|max:255',
    ]);

    // Use the authenticated user
    auth()->user()->chirps()->create($validated);

    return redirect('/')->with('success', 'Your chirp has been posted!');
}

public function edit(Chirp $chirp)
{
    $this->authorize('update', $chirp);

    return view('chirps.edit', compact('chirp'));
}

public function update(Request $request, Chirp $chirp)
{
    $this->authorize('update', $chirp);

    $validated = $request->validate([
        'message' => 'required|string|max:255',
    ]);

    $chirp->update($validated);

    return redirect('/')->with('success', 'Chirp updated!');
}

public function destroy(Chirp $chirp)
{
    $this->authorize('delete', $chirp);

    $chirp->delete();

    return redirect('/')->with('success', 'Chirp deleted!');
}
```
# Laravel Auth
- Hashes passwords with bcrypt
- Create session per login
- Set cookie to remember session
- Provide `auth()` helper to access current user
- Offer middleware to protect routes