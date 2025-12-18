<?php

namespace App\Http\Controllers;

use App\Models\Level;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use App\Models\level_type;
use Illuminate\Http\Request;
use Exception;

class LevelController extends Controller
{
    /**
     * Display all levels, optionally filtered by type
     */
    public function index(Request $request)
    {
        $topic = $request->query('topic');

        $query = Level::with('level_type');

        if ($topic && $topic != 'All') {
            $query->whereHas('level_type', function ($q) use ($topic) {
                $q->where('level_type_name', $topic);
            });
        }

        $levels = $query->get()->map(function ($level) {
            return [
                'level_id' => $level->level_id,
                'level_name' => $level->level_name,
                'level_type' => $level->level_type ? [
                    'level_type_id' => $level->level_type->level_type_id,
                    'level_type_name' => $level->level_type->level_type_name,
                ] : null,
            ];
        });

        return response()->json($levels);
    }

    public function singleLevel(Request $request, $levelId)
    {
        $level = Level::with('level_type')->find($levelId);

        $levelTypes = ["html", "css", "js", "php"];

        $levelDataObj = json_decode($level->level_data);
        $winDataObj = json_decode($level->win_condition);

        foreach ($levelTypes as $levelType) {
            $levelData = $levelDataObj->$levelType ?? null;
            if ($levelData === null)
                continue;

            $path = public_path("unity_build/StreamingAssets/{$levelType}/levelData.json");
            File::ensureDirectoryExists(dirname($path));
            File::put($path, $levelData);

            $winData = $winDataObj->$levelType ?? null;
            $path = public_path("unity_build/StreamingAssets/{$levelType}/winData.json");
            File::ensureDirectoryExists(dirname($path));
            File::put($path, $winData);
        }

        if (!$level) {
            return response()->json(['error' => 'Level not found'], 404);
        }

        $result = [
            'level_id' => $level->level_id,
            'level_name' => $level->level_name,
            'level_type' => $level->level_type ? [
                'level_type_id' => $level->level_type->level_type_id,
                'level_type_name' => $level->level_type->level_type_name,
            ] : null,
            'level_data' => $level->level_data,
            'win_condition' => $level->win_condition,
        ];

        return response()->json($result);
    }


    /**
     * Store a new level
     */
    public function store(Request $request)
    {
        $request->validate([
            'level_name' => 'required|string|filled',
            'level_type_name' => 'required|string',
        ]);

        $levelType = level_type::where('level_type_name', $request->level_type_name)->first();
        if (!$levelType) {
            return response()->json(['error' => 'Level type not found'], 404);
        }

        // $levelDataPath = public_path("unity_build/StreamingAssets/$levelType/levelData.json");
        // $winDataPath = public_path("unity_build/StreamingAssets/$levelType/winData.json");

        // if (!file_exists($levelDataPath) || !file_exists($winDataPath)) {
        //     return response()->json(['error' => 'Required JSON file not found'], 404);
        // }

        // $levelDataContent = file_get_contents($levelDataPath);
        // $winDataContent = file_get_contents($winDataPath);

        // $dataToBePassed = [
        //     'level_name' => $request->level_name,
        //     'level_type_id' => $levelType->level_type_id,
        //     'level_data' => $levelDataContent,
        //     'win_condition' => $winDataContent,
        // ];

        $levelTypes = ["html", "css", "js", "php"];
        $finalLevelData = [];
        $finalWinData = [];

        foreach ($levelTypes as $level_type) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$level_type/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$level_type/winData.json");

            $finalLevelData[$level_type] = file_exists($levelDataPath) ? file_get_contents($levelDataPath) : null;
            $finalWinData[$level_type] = file_exists($winDataPath) ? file_get_contents($winDataPath) : null;
        }

        $dataToBePassed = [
            'level_name' => $request->level_name,
            'level_type_id' => $levelType->level_type_id,
            'level_data' => json_encode($finalLevelData, JSON_PRETTY_PRINT),
            'win_condition' => json_encode($finalWinData, JSON_PRETTY_PRINT),
        ];


        try {
            $level = Level::create($dataToBePassed);
            $this->clearLevelFiles();

            return response()->json([
                'message' => 'Level created successfully',
                'level' => $level,
            ], 201);

        } catch (Exception $e) {
            //\Log::error('LEVEL_CREATE_FAILED: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to create level due to server error.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update a level
     */
    public function update(Request $request, $levelId)
    {
        $request->validate([
            'level_name' => 'required|string|filled',
            'level_type_name' => 'required|string|exists:level_types,level_type_name',
        ]);

        $level = Level::find($levelId);
        if (!$level) {
            return response()->json(['error' => 'Level not found'], 404);
        }

        $levelType = level_type::where('level_type_name', $request->level_type_name)->first();
        if (!$levelType) {
            return response()->json(['error' => 'Level type not found'], 404);
        }

        $levelTypes = ["html", "css", "js", "php"];
        $finalLevelData = [];
        $finalWinData = [];

        foreach ($levelTypes as $level_type) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$level_type/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$level_type/winData.json");

            $finalLevelData[$level_type] = file_exists($levelDataPath) ? file_get_contents($levelDataPath) : null;
            $finalWinData[$level_type] = file_exists($winDataPath) ? file_get_contents($winDataPath) : null;
        }

        $dataToBePassed = [
            'level_name' => $request->level_name,
            'level_type_id' => $levelType->level_type_id,
            'level_data' => json_encode($finalLevelData, JSON_PRETTY_PRINT),
            'win_condition' => json_encode($finalWinData, JSON_PRETTY_PRINT),
        ];

        $level->update($dataToBePassed);
        $level->refresh(); // ensures we return the updated model
        $this->clearLevelFiles();
        return response()->json(['message' => 'Level updated', 'level' => $level]);
    }


    /**
     * Delete a level
     */
    public function destroy($levelId)
    {
        $level = Level::find($levelId);
        if (!$level)
            return response()->json(['error' => 'Level not found'], 404);
        $levelType = $level->level_type->level_type_name;
        $level->delete();
        $this->clearLevelFiles();
        return response()->json(['message' => 'Level deleted']);
    }
    public function clearLevelFiles()
    {
        $levelTypes = ["html", "css", "js", "php"];
        foreach ($levelTypes as $levelType) {
            $levelDataPath = public_path("unity_build/StreamingAssets/$levelType/levelData.json");
            $winDataPath = public_path("unity_build/StreamingAssets/$levelType/winData.json");
            $indexFilePath = public_path("unity_build/StreamingAssets/$levelType/index.$levelType");
            // File::ensureDirectoryExists($levelDataPath);
            // File::ensureDirectoryExists($winDataPath);
            // File::ensureDirectoryExists($indexFilePath);
            File::put($levelDataPath, '');
            File::put($winDataPath, '');
            File::put($indexFilePath, '');
        }
    }

    public function saveToIndexFile(Request $request, $type)
    {
        $path = public_path("unity_build/StreamingAssets/$type/index.$type");
        File::ensureDirectoryExists(path: dirname($path));
        File::put($path, $request->getContent());
        return response('index file saved successfully', 200);
    }

    public function saveData(Request $request, $dataType, $type)
    {
        $path = public_path("unity_build/StreamingAssets/$type/{$dataType}Data.json");
        File::ensureDirectoryExists(dirname($path));
        File::put($path, $request->getContent());
        return response()->json(['status' => 'saved']);
    }

    public function getData (Request $request, $dataType, $type) {
    $path = public_path("unity_build/StreamingAssets/{$type}/{$dataType}Data.json");
    File::ensureDirectoryExists(dirname($path));

    if (!File::exists($path)) {
        return response('File not found', 404);
    }

    $content = File::get($path);

    // Return raw JSON content with correct header
    return response($content, 200)
        ->header('Content-Type', 'application/json');
}
}