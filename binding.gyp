{
  "targets": [
    {
      "target_name": "action_before_build",
      "type": "none",
      "copies": [],
      "conditions": [
        ['OS == "linux"', {
          "copies": [{
            "files": [ "/usr/lib/x86_64-linux-gnu/libmagic.a" ],
            "destination": "build/"
          }],
        }],
        ['OS == "mac"', {
          "copies": [{
            "files": [ "/usr/local/Cellar/libmagic/5.44/lib/libmagic.a" ],
            "destination": "build/"
          }],
        }],
      ],
    },
    {
      "target_name": "yara",
      "sources": [
        "src/yara.cc"
      ],
      "cflags_cc!": [
        "-fno-exceptions",
        "-fno-rtti"
      ],
      "include_dirs": [
        "<!(node -e 'require(\"nan\")')",
        "./build/yara/include"
      ],
      "libraries": [
        "../build/libmagic.a",
        "../build/yara/lib/libyara.a"
      ],
      "conditions": [
        [
          "OS==\"mac\"",
          {
            "xcode_settings": {
              "GCC_ENABLE_CPP_EXCEPTIONS": "YES"
            }
          }
        ]
      ],
      "actions": [
        {
          "action_name": "build_libyara",
          "inputs": [
            "deps"
          ],
          "outputs": [
            "build/yara"
          ],
          "action": [
            "make",
            "libyara"
          ]
        }
      ]
    }
  ]
}
