#include <idc.idc>

static main() {
 auto ea,base,s,f;
 s = AskFile(1,"*.txt", "Choose an output file");
 f = fopen(s,"w");

 if(f) {
    ea = NextFunction(0);

    for(ea = NextFunction(0); ea != BADADDR; ea = NextFunction(ea) ) {
        base = GetSegmentAttr(ea, SEGATTR_START);
        fprintf(f, "bp=fms.dll!%08lX, name=sub_%08lX\n", ea-base, ea-base);
    }

    fclose(f);
  }
}
