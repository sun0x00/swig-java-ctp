if not exist java_src md java_src

swig.exe -c++ -java -package xyz.redtorch.gateway.ctp.x64v6v3v19t1v.api -outdir java_src -o jctpv6v3v19t1x64api_wrap.cpp jctpv6v3v19t1x64api.i

pause
