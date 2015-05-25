/*
Copyright (C) University of Illinois, 1989-2013
Artem Shvorin art@shvorin.net, 2015

This software is derivative work from debug-conv++.C developed by the Parallel Programming Laboratory
in the Department of Computer Science at the University of Illinois at Urbana-Champaign.
*/

#include <cxxabi.h>

#include "converse.h"
#include "debug-conv++.h"
#include "cklists.h"

CpdListAccessor::~CpdListAccessor() { }
CpdSimpleListAccessor::~CpdSimpleListAccessor() { }
const char *CpdSimpleListAccessor::getPath(void) const {return path;}
size_t CpdSimpleListAccessor::getLength(void) const {return length;}
void CpdSimpleListAccessor::pup(PUP::er &p,CpdListItemsRequest &req)
{
        for (int i=req.lo;i<req.hi;i++) {
                beginItem(p,i);
                (*pfn)(p,i);
        }
}

static void CpdListBeginItem_impl(PUP::er &p,int itemNo)
{
        p.syncComment(PUP::sync_item);
}

extern "C" void CpdListBeginItem(pup_er p,int itemNo)
{
  CpdListBeginItem_impl(*(PUP::er *)p,itemNo);
}

void CpdListAccessor::beginItem(PUP::er &p,int itemNo)
{
  CpdListBeginItem_impl(p,itemNo);
}

extern "C" {
  /* plain C wrapper for abi::__cxa_demangle */
  char *cxa_demangle(const char *mangled_name, char *output_buffer, size_t *length, int *status)
  {
    return abi::__cxa_demangle(mangled_name, output_buffer, length, status);
  }
}
