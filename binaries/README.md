Binaries
========

These are pre-build binaries coming from the GH Action in this repository. They're used by `node-gyp` and fetched when you run `npm i` for `node-yara` package.

For instance:

```
node-yara$ npm i

> @automattic/yara@2.4.0 install
> node-pre-gyp install --fallback-to-build

node-pre-gyp info it worked if it ends with ok
node-pre-gyp info using node-pre-gyp@1.0.10
node-pre-gyp info using node@16.16.0 | linux | x64
node-pre-gyp info check checked for "/tmp/node-yara/build/Release/yara.node" (not found)
node-pre-gyp http GET https://github.com/Automattic/node-yara/raw/master/binaries/yara-v2.4.0-linux-x64.tar.gz
node-pre-gyp info install unpacking Release/.deps/Release/obj.target/yara/src/yara.o.d
node-pre-gyp info install unpacking Release/.deps/Release/obj.target/yara.node.d
node-pre-gyp info install unpacking Release/.deps/Release/yara.node.d
node-pre-gyp info install unpacking Release/.deps/build/yara.d
node-pre-gyp info install unpacking Release/obj.target/yara/src/yara.o
node-pre-gyp info install unpacking Release/obj.target/yara.node
node-pre-gyp info extracted file count: 6 
[@automattic/yara] Success: "/tmp/node-yara/build/Release/yara.node" is installed via remote
node-pre-gyp info ok 
node-pre-gyp info install unpacking Release/yara.node

up to date, audited 119 packages in 4s

22 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Node.js ABI versions

* Node.js 16.x - `v93`
* Node.js 18.x - `v108`
* Node.js 20.x - `v115`
* Node.js 22.x - `v127`
