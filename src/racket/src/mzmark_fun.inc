/* >>>> Generated by mkmark.rkt from mzmarksrc.c <<<< */

static int mark_closure_info_SIZE(void *p, struct NewGC *gc) {
  return
  gcBYTES_TO_WORDS(sizeof(Closure_Info));
}

static int mark_closure_info_MARK(void *p, struct NewGC *gc) {
  Closure_Info *i = (Closure_Info *)p;
  
  gcMARK2(i->local_flags, gc);
  gcMARK2(i->base_closure_map, gc);
  gcMARK2(i->flonum_map, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Closure_Info));
}

static int mark_closure_info_FIXUP(void *p, struct NewGC *gc) {
  Closure_Info *i = (Closure_Info *)p;
  
  gcFIXUP2(i->local_flags, gc);
  gcFIXUP2(i->base_closure_map, gc);
  gcFIXUP2(i->flonum_map, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Closure_Info));
}

#define mark_closure_info_IS_ATOMIC 0
#define mark_closure_info_IS_CONST_SIZE 1


static int mark_dyn_wind_cell_SIZE(void *p, struct NewGC *gc) {
  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Dynamic_Wind_List));
}

static int mark_dyn_wind_cell_MARK(void *p, struct NewGC *gc) {
  Scheme_Dynamic_Wind_List *l = (Scheme_Dynamic_Wind_List *)p;
  
  gcMARK2(l->dw, gc);
  gcMARK2(l->next, gc);
  
  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Dynamic_Wind_List));
}

static int mark_dyn_wind_cell_FIXUP(void *p, struct NewGC *gc) {
  Scheme_Dynamic_Wind_List *l = (Scheme_Dynamic_Wind_List *)p;
  
  gcFIXUP2(l->dw, gc);
  gcFIXUP2(l->next, gc);
  
  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Dynamic_Wind_List));
}

#define mark_dyn_wind_cell_IS_ATOMIC 0
#define mark_dyn_wind_cell_IS_CONST_SIZE 1


static int mark_dyn_wind_info_SIZE(void *p, struct NewGC *gc) {
  return
   gcBYTES_TO_WORDS(sizeof(Dyn_Wind));
}

static int mark_dyn_wind_info_MARK(void *p, struct NewGC *gc) {
  Dyn_Wind *d = (Dyn_Wind *)p;
  
  gcMARK2(d->pre, gc);
  gcMARK2(d->act, gc);
  gcMARK2(d->post, gc);

  return
   gcBYTES_TO_WORDS(sizeof(Dyn_Wind));
}

static int mark_dyn_wind_info_FIXUP(void *p, struct NewGC *gc) {
  Dyn_Wind *d = (Dyn_Wind *)p;
  
  gcFIXUP2(d->pre, gc);
  gcFIXUP2(d->act, gc);
  gcFIXUP2(d->post, gc);

  return
   gcBYTES_TO_WORDS(sizeof(Dyn_Wind));
}

#define mark_dyn_wind_info_IS_ATOMIC 0
#define mark_dyn_wind_info_IS_CONST_SIZE 1


static int mark_cont_mark_chain_SIZE(void *p, struct NewGC *gc) {
  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Cont_Mark_Chain));
}

static int mark_cont_mark_chain_MARK(void *p, struct NewGC *gc) {
  Scheme_Cont_Mark_Chain *c = (Scheme_Cont_Mark_Chain *)p;
  
  gcMARK2(c->key, gc);
  gcMARK2(c->val, gc);
  gcMARK2(c->next, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Cont_Mark_Chain));
}

static int mark_cont_mark_chain_FIXUP(void *p, struct NewGC *gc) {
  Scheme_Cont_Mark_Chain *c = (Scheme_Cont_Mark_Chain *)p;
  
  gcFIXUP2(c->key, gc);
  gcFIXUP2(c->val, gc);
  gcFIXUP2(c->next, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Cont_Mark_Chain));
}

#define mark_cont_mark_chain_IS_ATOMIC 0
#define mark_cont_mark_chain_IS_CONST_SIZE 1


#ifdef MZ_USE_JIT

static int mark_lightweight_cont_SIZE(void *p, struct NewGC *gc) {
  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Lightweight_Continuation));
}

static int mark_lightweight_cont_MARK(void *p, struct NewGC *gc) {
  Scheme_Lightweight_Continuation *lw = (Scheme_Lightweight_Continuation *)p;

  gcMARK2(lw->saved_lwc, gc);
  gcMARK2(lw->stack_slice, gc);
  gcMARK2(lw->runstack_slice, gc);
  gcMARK2(lw->cont_mark_stack_slice, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Lightweight_Continuation));
}

static int mark_lightweight_cont_FIXUP(void *p, struct NewGC *gc) {
  Scheme_Lightweight_Continuation *lw = (Scheme_Lightweight_Continuation *)p;

  gcFIXUP2(lw->saved_lwc, gc);
  gcFIXUP2(lw->stack_slice, gc);
  gcFIXUP2(lw->runstack_slice, gc);
  gcFIXUP2(lw->cont_mark_stack_slice, gc);

  return
  gcBYTES_TO_WORDS(sizeof(Scheme_Lightweight_Continuation));
}

#define mark_lightweight_cont_IS_ATOMIC 0
#define mark_lightweight_cont_IS_CONST_SIZE 1


#endif

