<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class LevelSeeder extends Seeder
{
    public function run(): void
    {
        $cssTypeId = DB::table('level_types')->where('level_type_name', 'CSS')->value('level_type_id');
        $htmlTypeId = DB::table('level_types')->where('level_type_name', 'HTML')->value('level_type_id');

        DB::table('levels')->insert([

            /* -------------------------------
             * CSS LEVEL 1
             * ------------------------------- */
            [
                'level_id' => Str::uuid7(),
                'level_name' => 'css level 1: atribut',
                'level_type_id' => $cssTypeId,

                'level_data' => json_encode([
                    "html" => "",
                    "css" => json_encode([
                        "questionData" => "tambah blok attribute baharu dengan attribute \"height\", 100px",
                        "CSSTagData" => [
                            [
                                "tagType" => "selector",
                                "values"   => ["div"],
                                "locked"   => false
                            ],
                            [
                                "tagType" => "attribute",
                                "values"   => ["width", "100px"],
                                "locked"   => false
                            ],
                            [
                                "tagType" => "selectorCloser",
                                "values"   => [],
                                "locked"   => false
                            ],
                        ]
                    ]),
                    "js" => "",
                    "php" => ""
                ]),

                'win_condition' => json_encode([
                    "html" => "",
                    "css" => json_encode([
                        "questionData" => "tambah blok attribute baharu dengan attribute \"height\", 100px",
                        "CSSTagData" => [
                            [
                                "tagType" => "selector",
                                "values"   => ["div"],
                                "locked"   => false
                            ],
                            [
                                "tagType" => "attribute",
                                "values"   => ["width", "100px"],
                                "locked"   => false
                            ],
                            [
                                "tagType" => "attribute",
                                "values"   => ["height", "100px"],
                                "locked"   => false
                            ],
                            [
                                "tagType" => "selectorCloser",
                                "values"   => [],
                                "locked"   => false
                            ],
                        ]
                    ]),
                    "js" => "",
                    "php" => ""
                ]),

                'created_at' => now(),
                'updated_at' => now(),
            ],

            /* -------------------------------
             * HTML LEVEL 1
             * ------------------------------- */
            [
                'level_id' => Str::uuid7(),
                'level_name' => 'html level 1: <p>',
                'level_type_id' => $htmlTypeId,

                'level_data' => json_encode([
                    "html" => json_encode([
                        "questionData" =>
                            "tambahkan <p> tag dalam kurungan tag <html> dengan perkataan \"Hello world!\"
Perkataannya MESTI seiring dengan apa yang dinyatakan untuk ditanda betul oleh sistem",
                        "tagData" => [
                            [
                                "tagType" => "double",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                            [
                                "tagType" => "closingTag",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                        ]
                    ]),
                    "css" => "",
                    "js" => "",
                    "php" => ""
                ]),

                'win_condition' => json_encode([
                    "html" => json_encode([
                        "questionData" =>
                            "tambahkan <p> tag dalam kurungan tag <html> dengan perkataan \"Hello world!\"
Perkataannya MESTI seiring dengan apa yang dinyatakan untuk ditanda betul oleh sistem",
                        "tagData" => [
                            [
                                "tagType" => "double",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                            [
                                "tagType" => "single",
                                "tagName" => "p",
                                "hexColor" => "#AABBCC",
                                "locked" => false,
                                "attributes" => [],
                                "inputValues" => "Hello world!"
                            ],
                            [
                                "tagType" => "closingTag",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                        ]
                    ]),
                    "css" => "",
                    "js" => "",
                    "php" => ""
                ]),

                'created_at' => now(),
                'updated_at' => now(),
            ],

            /* -------------------------------
             * HTML LEVEL 2 (style attribute)
             * ------------------------------- */
            [
                'level_id' => Str::uuid7(),
                'level_name' => 'html level 2: style',
                'level_type_id' => $htmlTypeId,

                'level_data' => json_encode([
                    "html" => json_encode([
                        "questionData" =>
                            "tambahkan <p> dengan perkataan \"in-line\", dan tambahkan atribut style secara in-line untuk mewarnakan perkataannya kepada merah.\n\nhint: untuk tambahkan in-line atribut, tekan arrow kecil yang berada di kanan blok level",
                        "tagData" => [
                            [
                                "tagType" => "double",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                            [
                                "tagType" => "closingTag",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                        ]
                    ]),
                    "css" => "",
                    "js" => "",
                    "php" => ""
                ]),

                'win_condition' => json_encode([
                    "html" => json_encode([
                        "questionData" =>
                            "tambahkan <p> dengan perkataan \"in-line\", dan tambahkan atribut style secara in-line untuk mewarnakan perkataannya kepada merah.\n\nhint: untuk tambahkan in-line atribut, tekan arrow kecil yang berada di kanan blok level",
                        "tagData" => [
                            [
                                "tagType" => "double",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                            [
                                "tagType" => "single",
                                "tagName" => "p",
                                "hexColor" => "#AABBCC",
                                "locked" => false,
                                "attributes" => [
                                    [
                                        "attributeName" => "style",
                                        "attributeValue" => "color: red"
                                    ]
                                ],
                                "inputValues" => "in-line"
                            ],
                            [
                                "tagType" => "closingTag",
                                "tagName" => "html",
                                "hexColor" => "#FFCC33",
                                "locked" => true,
                                "attributes" => [],
                                "inputValues" => ""
                            ],
                        ]
                    ]),
                    "css" => "",
                    "js" => "",
                    "php" => ""
                ]),

                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
