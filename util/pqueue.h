#ifndef INCLUDED_PQUEUE_H
#define INCLUDED_PQUEUE_H

/* Priority queue. Uses an invasive data structure.  Add a member of
 * type pqueue_ent to whatever structure you want a queue of, and
 * pass its offset in the structure to pqueue_new.  Do not write
 * to the pqueue_ent elements. Threadsafe except obvious race between
 * peek and remove - peek does not lock an element and if threads race
 * to remove elements from the queue there's no guarantee that the peeked
 * entry is the one consumed.  Otherwise no need to lock around
 * pqueue calls, it'll acquire locks internally as needed. */

/* pqueue.c */
struct pqueue_ent {
    int ix;
    int priority;
};

/* Crate pqueue.  Pass the offset of pqueue_ent in your structure. pqueue
 * will write to the pqueue_ent as needed but will not write to/move/reallocate
 * the structure itself. */
struct pqueue *pqueue_new(int off);

/* Add an item with a given priority. */
int pqueue_add(struct pqueue *pq, void *ent, int priority);

/* Remove the lowest priority item from the queue and return it. */
void *pqueue_remove_next(struct pqueue *pq);

/* Peek at the first element in the queue (lowest priority).  See dire
 * warning in the file header above. */
void *pqueue_peek_next(struct pqueue *pq);

/* Delete a given item from a priority queue.  Undefined behavior if the
 * item was never added, or already removed. */
void pqueue_delete(struct pqueue *pq, void *item);

/* Adjust the priority of a given item in the queue to a new value.  Undefined
 * behavior if it was never added or has already beeen removed. */
void pqueue_adjust_priority(struct pqueue *pq, void *item, int new_priority);

/* Destroy all resources associated with a queue.  Does not modify any items
 * remaining in the queue. */
void pqueue_destroy(struct pqueue *pq);

#endif
