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
        
        // Pattern for Vercel preview deployments
        $vercelPattern = '#^https://kalmnest-.*\.vercel\.app$#';
        
        // Handle preflight OPTIONS request
        if ($request->getMethod() === 'OPTIONS') {
            $response = response()->json([], 200);
        } else {
            $response = $next($request);
        }

        // ALWAYS add CORS headers - check origin and set accordingly
        if ($origin) {
            // Check if it's a Vercel domain (pattern match)
            if (preg_match($vercelPattern, $origin)) {
                $response->headers->set('Access-Control-Allow-Origin', $origin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
            } 
            // Check exact matches
            elseif (in_array($origin, [
                'https://kalmnest-one.vercel.app',
                'https://kalmnest-git-main-tan-li-jis-projects.vercel.app',
                'https://kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app',
                'http://localhost',
                'http://localhost:3000',
                'http://127.0.0.1:8000',
                'https://kalmnest.test',
            ])) {
                $response->headers->set('Access-Control-Allow-Origin', $origin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
            }
            // Allow any origin for debugging (can be restricted later)
            else {
                $response->headers->set('Access-Control-Allow-Origin', $origin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
            }
        }

        // Always add these CORS headers
        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, X-XSRF-TOKEN');
        $response->headers->set('Access-Control-Max-Age', '3600');

        return $response;
    }
}
