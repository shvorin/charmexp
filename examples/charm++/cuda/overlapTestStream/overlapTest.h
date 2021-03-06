#ifndef __OVERLAP_TEST_H
#define __OVERLAP_TEST_H

#include "overlapTestConsts.h"

class Main : public CBase_Main {
 private:
  CProxy_Workers workers; 
  int numChares; 
  double startTime; 
  
 public:
  Main(CkArgMsg *m);
  void finishWork(CkReductionMsg *m); 
};


class Workers: public CBase_Workers {
 private:
  ElementType *A;
  ElementType *B; 
  ElementType *C; 
  
 public:
  Workers(); 
  ~Workers();
  Workers(CkMigrateMessage *msg);
  void beginWork(); 
};

void randomInit(ElementType *data, int size);

#endif
