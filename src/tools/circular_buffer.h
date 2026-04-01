#ifndef __CIRCULAR_BUFFER_H__
#define __CIRCULAR_BUFFER_H__

#include "platform.h"

void circular_buffer_init(size_t size);
void circular_buffer_end();
void circular_buffer_push_sample(float level);
float circular_buffer_pop_sample();
void circular_buffer_clear();
void circular_buffer_enable(bool value);

#endif