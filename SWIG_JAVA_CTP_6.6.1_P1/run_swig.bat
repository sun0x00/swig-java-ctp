if not exist java_src md java_src

swig.exe -c++ -java -package xyz.redtorch.gateway.ctp.x64v6v6v1p1v.api -outdir java_src -o jctpv6v6v1p1x64api_wrap.cpp jctpv6v6v1p1x64api.i

pause
