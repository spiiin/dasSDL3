#include "daScript/daScript.h"
#include "dasSDL3Probe.h"
#include <cstring>
using namespace das;
int run(const char *path, bool aot) {
 TextPrinter out; ModuleGroup modules; CodeOfPolicies policies;
 policies.aot=aot; policies.fail_on_no_aot=aot;
 auto program=compileDaScript(path,make_smart<FsFileAccess>(),out,modules,policies);
 auto errors=[&] { for(auto &e:program->errors) out<<reportError(e.at,e.what,e.extra,e.fixme,e.cerr); };
 if(program->failed()){errors(); return 1;}
 Context context(program->getContextStackSize());
 if(!program->simulate(context,out)){errors(); return 2;}
 auto fn=context.findFunction("main");
 if(!fn || !verifyCall<int32_t>(fn->debugInfo,modules)) return 3;
 out<<"main AOT="<<(fn->aot?"yes":"no")<<"\n";
 if(bool(fn->aot)!=aot) return 4;
 auto value=context.evalWithCatch(fn,nullptr);
 if(context.getException()){out<<context.getException()<<"\n";return 5;}
 return cast<int32_t>::to(value);
}
int main(int argc,char **argv) {
 if(argc!=4)return 6;
 setDasRoot(argv[1]); NEED_ALL_DEFAULT_MODULES;
 new Module_dasSDL3Probe(); Module::Initialize();
 int result=run(argv[2],std::strcmp(argv[3],"aot")==0);
 Module::Shutdown(); return result;
}
