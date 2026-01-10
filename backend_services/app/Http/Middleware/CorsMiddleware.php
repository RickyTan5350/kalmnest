<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $origin = $request->headers->get('Origin');
        
        // Define allowed origins (hardcoded for reliability)
        $allowedOrigins = [
            'https://kalmnest-one.vercel.app',
            'https://kalmnest-git-main-tan-li-jis-projects.vercel.app',
            'https://kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app',
            'http://localhost',
            'http://localhost:3000',
            'http://127.0.0.1:8000',
            'https://kalmnest.test',
        ];
        
        // Pattern for Vercel preview deployments
        $vercelPattern = '#^https://kalmnest-.*\.vercel\.app$#';
        
        // Check if origin is allowed
        $isAllowed = false;
        if ($origin) {
            // Check exact match
            if (in_array($origin, $allowedOrigins)) {
                $isAllowed = true;
            } 
            // Check Vercel pattern
            elseif (preg_match($vercelPattern, $origin)) {
                $isAllowed = true;
            }
        }

        // Handle preflight OPTIONS request
        if ($request->getMethod() === 'OPTIONS') {
            $response = response('', 200);
        } else {
            $response = $next($request);
        }

        // Add CORS headers
        if ($isAllowed && $origin) {
            $response->headers->set('Access-Control-Allow-Origin', $origin);
            $response->headers->set('Access-Control-Allow-Credentials', 'true');
        } elseif ($origin && preg_match($vercelPattern, $origin)) {
            // Allow Vercel preview deployments
            $response->headers->set('Access-Control-Allow-Origin', $origin);
            $response->headers->set('Access-Control-Allow-Credentials', 'true');
        } else {
            // For debugging: allow the origin if provided
            if ($origin) {
                $response->headers->set('Access-Control-Allow-Origin', $origin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
            }
        }

        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, X-XSRF-TOKEN');
        $response->headers->set('Access-Control-Max-Age', '3600');

        return $response;
    }
}
