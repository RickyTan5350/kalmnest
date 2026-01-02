<?php

$providers = [
    App\Providers\AppServiceProvider::class,
];

// Only register Telescope in development or if it's installed
if (app()->environment('local') || class_exists(\Laravel\Telescope\TelescopeApplicationServiceProvider::class)) {
    $providers[] = App\Providers\TelescopeServiceProvider::class;
}

return $providers;
