#include <pthread.h>
#include <stdlib.h>
#include <stdio.h> 
#include <stddef.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>

#include <unistd.h>
#include "pqueue.h"

// Must have this in a structure, pass it's offset to pqueue_new

struct pqueue {
    int off;
    int count;
    int allocated;
    void **entries;
    pthread_mutex_t lk;
};

struct pqueue* pqueue_new(int off) {
    struct pqueue *pq;
    pq = malloc(sizeof(struct pqueue));
    pq->off = off;
    pq->count = pq->allocated = 0;
    pq->entries = NULL;
    int rc;
    rc = pthread_mutex_init(&pq->lk, NULL);
    if (rc)
        abort();
    return pq;
}

#define left(n) (((n + 1) * 2) - 1)
#define right(n) (((n + 1) * 2))
#define parent(n) ((n + 1) / 2 - 1)

#define ent(n) ((struct pqueue_ent*) ((char*) pq->entries[n] + pq->off))

static void swap(struct pqueue *pq, int e1, int e2) {
    assert(e1 < pq->count);
    assert(e2 < pq->count);
    assert(e1 >= 0);
    assert(e2 >= 0);
    assert(e1 != e2);

    void *tmp;
    tmp = pq->entries[e1];
    pq->entries[e1] = pq->entries[e2];
    pq->entries[e2] = tmp;
    
    struct pqueue_ent *ee1, *ee2;
    ee1 = ent(e1);
    ee2 = ent(e2);

    ee1->ix = e1;
    ee2->ix = e2;
}

static void fixup(struct pqueue *pq, int id) {
    struct pqueue_ent *c, *p;
    assert(id < pq->count);

    while (id > 0) {
        c = ent(id);
        p = ent(parent(id));

        if (c->priority < p->priority) {
            swap(pq, id, parent(id));
        }
        else
            break;
        id = parent(id);
        c = ent(id);
    }
}

static void fixdown(struct pqueue *pq, int id) {
    assert(pq->count > 0);

    // current, left, right, next
    struct pqueue_ent *c, *l, *r, *n;
    // can have 0, 1, or 2 children
    while (left(id) < pq->count) {
        // have 1 child? swap if it's smaller
        if (right(id) >= pq->count) {
            c = ent(id);
            l = ent(left(id));
            if (l->priority < c->priority)
                swap(pq, id, left(id));
            id = left(id);
        }
        // have 2 children? swap with smallest if smaller than us
        else {
            int nextix;
            c = ent(id);
            r = ent(right(id));
            l = ent(left(id));
            if (r->priority < l->priority) {
                nextix = right(id);
                n = r;
            }
            else {
                nextix = left(id);
                n = l;
            }
            if (n->priority < c->priority ) {
                swap(pq, id, nextix);
            }
            id = nextix;
        }
    }
}

static void check(struct pqueue *pq) {
    return;

    struct pqueue_ent *c, *l, *r, *p;
    for (int i = 0; i < pq->count; i++) {
        c = ent(i);
        if (c->ix != i)
            abort();
        if (left(i) < pq->count) {
            l = ent(left(i));
            if (c->priority > l->priority)
                abort();
        }
        if (right(i) < pq->count) {
            r = ent(right(i));
            if (c->priority > r->priority)
                abort();
        }
        if (parent(i) > 0) {
            p = ent(parent(i));
            if (p->priority > c->priority)
                abort();
        }
    }
}

static int pqueue_add_locked(struct pqueue *pq, void *ent, int priority) {
    struct pqueue_ent *c;

    if (pq->count >= pq->allocated) {
        int allocated = pq->allocated * 2 + 16;
        void *p = realloc(pq->entries, sizeof(void*) * allocated);
        if (p == NULL)
            return -1;
        pq->allocated = allocated;
        pq->entries = p;
    }
    pq->entries[pq->count] = ent;
    c = ent(pq->count);
    c->priority = priority;
    c->ix = pq->count;
    pq->count++;
    fixup(pq, pq->count-1);
    check(pq);

    return 0;
}

int pqueue_add(struct pqueue *pq, void *ent, int priority) {
    int rc;

    pthread_mutex_lock(&pq->lk);
    rc = pqueue_add_locked(pq, ent, priority);
    pthread_mutex_unlock(&pq->lk);
    
    return rc;
}

void* pqueue_remove_next(struct pqueue *pq) {
    void *p;
    pthread_mutex_lock(&pq->lk);
    if (pq->count == 0) {
        pthread_mutex_unlock(&pq->lk);
        return NULL;
    }
    p = pq->entries[0];
    pq->count--;
    if (pq->count > 0) {
        pq->entries[0] = pq->entries[pq->count];
        struct pqueue_ent *e = ent(0);
        e->ix = 0;
        fixdown(pq, 0);
    }
    check(pq);
    pthread_mutex_unlock(&pq->lk);

    return p;
}

void* pqueue_peek_next(struct pqueue *pq) {
    void *p;
    pthread_mutex_lock(&pq->lk);
    if (pq->count == 0)
        p = NULL;
    else
        p = pq->entries[0];
    pthread_mutex_unlock(&pq->lk);
    return p;
}

static void pqueue_delete_locked(struct pqueue *pq, void *item) {
    struct pqueue_ent *e, *p;
    int ix;
    e = (struct pqueue_ent*) (((char*)item) + pq->off);
    ix = e->ix;
    pq->entries[ix] = pq->entries[pq->count-1];
    pq->count--;
    e = ent(ix);
    e->ix = ix;
    if (ix == 0) {
        if (pq->count > 0)
            fixdown(pq, ix);
    }
    else {
        p = ent(parent(ix));
        if (e->priority < p->priority)
            fixup(pq, ix);
        else
            fixdown(pq, ix);
    }
    check(pq);
}

void pqueue_delete(struct pqueue *pq, void *item) {
    pthread_mutex_lock(&pq->lk);
    pqueue_delete_locked(pq, item);
    pthread_mutex_unlock(&pq->lk);
}

void pqueue_adjust_priority(struct pqueue *pq, void *item, int new_priority) {
    pthread_mutex_lock(&pq->lk);
    pqueue_delete_locked(pq, item);
    pqueue_add_locked(pq, item, new_priority);
    pthread_mutex_unlock(&pq->lk);
}

struct s {
    int pri;
    int returned;
    struct pqueue_ent ent;
};

void pqueue_destroy(struct pqueue *pq) {
    pthread_mutex_destroy(&pq->lk);
    free(pq->entries);
    free(pq);
}

#ifdef TEST_PQUEUE
#define N 1000000
struct s e[N];

int main(int argc, char *argv[]) {
    srand(getpid() << 16 ^ time(NULL));
    struct pqueue *pq = pqueue_new(offsetof(struct s, ent));
    int ok = 0;

    for (int iter = 0; iter < 10; iter++) {
        // add and drain entries
        for (int i = 0; i < N; i++) {
            e[i].pri = 1 + rand() % N;
            e[i].returned = 0;
            pqueue_add(pq, &e[i], e[i].pri);
        }
        int last = -1;
        struct s *p = pqueue_remove_next(pq);
        while (p) {
            assert(p->pri >= last);
            assert(p >= &e[0] && p < &e[N]);
            last = p->pri;
            p->returned++;
            // make sure we didn't double-return
            assert(p->returned == 1);
            p = pqueue_remove_next(pq);
        }

        // make sure we returned everything
        for (int i = 0; i < N; i++) {
            assert(e[i].returned == 1);
        }

        // add and delete arbitrary entries
        for (int i = 0; i < N; i++) {
            e[i].pri = 1 + rand() % N;
            e[i].returned = 0;
            pqueue_add(pq, &e[i], e[i].pri);
        }
        for (int i = 0; i < N/2; i++) {
            pqueue_delete(pq, &e[i]);
        }
        last = -1;
        p = pqueue_remove_next(pq);
        while (p) {
            assert(p->pri >= last);
            assert(p >= &e[0] && p < &e[N]);
            last = p->pri;
            p->returned++;
            // make sure we didn't double-return
            assert(p->returned == 1);
            p = pqueue_remove_next(pq);
        }
        // make sure we didn't return these
        for (int i = 0; i < N/2; i++) {
            assert(e[i].returned == 0);
        }
        // make sure we returned the rest
        for (int i = N/2; i < N; i++) {
            assert(e[i].returned == 1);
        }

        // add and reassign priorities
        for (int i = 0; i < N; i++) {
            e[i].pri = 1 + rand() % N;
            e[i].returned = 0;
            pqueue_add(pq, &e[i], e[i].pri);
        }
        for (int i = N/2; i < N; i++) {
            e[i].pri = i * 1000;
            pqueue_adjust_priority(pq, &e[i], i * 1000);
        }
        last = -1;
        p = pqueue_remove_next(pq);
        int expected = N/2 * 1000;
        while (p) {
            assert(p->pri >= last);
            assert(p >= &e[0] && p < &e[N]);
            last = p->pri;
            p->returned++;
            if (p < &e[N/2]) {
                assert(p->returned == 1);
                assert(p->pri <= N);
            }
            else {
                assert(p->returned == 1);
                assert(p->pri == expected);
                expected += 1000;
            }
            p = pqueue_remove_next(pq);
        }
        // make sure we returned everything
        for (int i = 0; i < N; i++) {
            assert(e[i].returned == 1);
        }

        printf("%d\n", ok++);
    }

    return 0;
}
#endif
