#include "converse.h"
#include "envelope.h"
#include <algorithm>
#include <limits>
#include "alignmentCheck.decl.h"

static const int varSize1 = 7;
static const int varSize2 = 14;
static const int nCheck = 10;

class TestMessage : public CMessage_TestMessage {
public:
  char *varArray1;
  char *varArray2;
};

int alignCheck(intptr_t ptrToInt) {
  intptr_t align = 1;
  while ((ptrToInt & ~(align - 1)) == ptrToInt) {
    align <<= 1;
  }
  align >>= 1;
  return align;
}

void alignmentTest(std::vector<TestMessage*> &allMsgs, const std::string &identifier) {

  int alignHdr = std::numeric_limits<int>::max();
  int alignEnv = std::numeric_limits<int>::max();
  int alignUsr = std::numeric_limits<int>::max();
  int alignVar1 = std::numeric_limits<int>::max();
  int alignVar2 = std::numeric_limits<int>::max();
  int alignPrio = std::numeric_limits<int>::max();

  for (int i = 0; i < allMsgs.size(); i++) {
    TestMessage *msg = allMsgs[i];
    envelope *env = UsrToEnv(msg);

#if CMK_USE_IBVERBS | CMK_USE_IBUD
    intptr_t startHdr = (intptr_t) &(((infiCmiChunkHeader *) env)[-1]);
#else
    intptr_t startHdr = (intptr_t) BLKSTART(env);
#endif
    intptr_t startEnv = (intptr_t) env;
    intptr_t startUsr = (intptr_t) msg;
    intptr_t startVar1 = (intptr_t) msg->varArray1;
    intptr_t startVar2 = (intptr_t) msg->varArray2;
    intptr_t startPrio = (intptr_t) env->getPrioPtr();

    if (! (startHdr < startEnv && startEnv < startUsr &&
           startUsr <= startVar1 && startVar1 < startVar2 &&
           startVar2 < startPrio)) {
      CkAbort("Charm++ fatal error. Pointers to component fields "
              "of a message do not follow an increasing order.\n");
    }
    alignHdr = std::min(alignCheck(startHdr), alignHdr);
    alignEnv = std::min(alignCheck(startEnv), alignEnv);
    alignUsr = std::min(alignCheck(startUsr), alignUsr);
    alignVar1 = std::min(alignCheck(startVar1), alignVar1);
    alignVar2 = std::min(alignCheck(startVar2), alignVar2);
    alignPrio = std::min(alignCheck(startPrio), alignPrio);
  }

  CkPrintf("Alignment information at the %s:\n", identifier.c_str());
  CkPrintf("Chunk header aligned to %d bytes\n", alignHdr);
  CkPrintf("Envelope aligned to %d bytes\n", alignEnv);
  CkPrintf("Start of user data aligned to %d bytes\n", alignUsr);
  CkPrintf("First varsize array aligned to %d bytes\n", alignVar1);
  CkPrintf("Second varsize array aligned to %d bytes\n", alignVar2);
  CkPrintf("Priority field aligned to %d bytes\n", alignPrio);

  if (alignEnv >= ALIGN_BYTES && alignUsr >= ALIGN_BYTES &&
      alignVar1 >= ALIGN_BYTES && alignVar2 >= ALIGN_BYTES &&
      alignHdr >= ALIGN_BYTES && alignPrio >= ALIGN_BYTES) {
    CkPrintf("All passed.\n");
  }
  else {
    CkAbort("Alignment requirements failed.\n");
  }

}

class TestDriver : public CBase_TestDriver {
public:

  TestDriver(CkArgMsg *m) {
    delete m;

    CProxy_Destination destinationChare =
      CProxy_Destination::ckNew(CkNumPes() - 1);

    CkPrintf("Size of Converse envelope: %d bytes\n", CmiReservedHeaderSize);
    CkPrintf("Size of Charm++ envelope: %d bytes\n", sizeof(envelope));
    CkPrintf("Default alignment: %d bytes\n", ALIGN_BYTES);

    int msgSizes[] = {varSize1, varSize2};
    std::vector<TestMessage *> allMsgs;
    int prio = 1234;
    for (int i = 0; i < nCheck; i++) {
      TestMessage *msg = new (msgSizes, prio) TestMessage();
      allMsgs.push_back(msg);
    }
    alignmentTest(allMsgs, "source");

    for (int i = 0; i < allMsgs.size(); i++) {
      destinationChare.receiveMessage(allMsgs[i]);
    }
  }

};

class Destination: public CBase_Destination {

private:
  std::vector<TestMessage *> allMsgs;

public:

  void receiveMessage(TestMessage *msg) {
    allMsgs.push_back(msg);
    if (allMsgs.size() == nCheck) {
      alignmentTest(allMsgs, "destination");
      for (int i = 0; i < allMsgs.size(); i++) {
        delete allMsgs[i];
      }
      CkExit();
    }
  }

};

#include "alignmentCheck.def.h"
