#ifndef __CIRCULAR_BUFFER_H__
#define __CIRCULAR_BUFFER_H__

void circular_buffer_init(size_t size);
void circular_buffer_end();
void circular_buffer_push_sample(float level);
float circular_buffer_pop_sample();
void circular_buffer_clear();

#endif