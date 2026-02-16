#pragma once

#include <queue>
#include <semaphore>
#include <mutex>
#include <chrono>
#include <thread>
#include <functional>

namespace stdext {
	template <typename T, int maxElements = std::numeric_limits<int>::max()>
	class Queue : private std::queue<T>
	{
	public:
		T& emplace(uint64_t c, float v) {
			std::lock_guard lck(mtx);
			if (reinterpret_cast<std::queue<T>*>(this)->size() < maxElements) {
				reinterpret_cast<std::queue<T>*>(this)->emplace(c, v);
				sem.release();
				return reinterpret_cast<std::queue<T>*>(this)->back();
			}
		}
		bool push(const T& t) {
			std::lock_guard lck(mtx);
			if (reinterpret_cast<std::queue<T>*>(this)->size() < maxElements) {
				reinterpret_cast<std::queue<T>*>(this)->push(std::move(t));
				sem.release();
				return true;
			}
			return false;
		}

		bool pop(T& t, uint64_t tout = 10000000000) {

			if (sem.try_acquire_for(std::chrono::milliseconds(tout))) {
				std::lock_guard lck(mtx);
				if (this->size() > 0) {
					t = std::move(this->front());
					reinterpret_cast<std::queue<T>*>(this)->pop();
					return true;
				}
			}
			return false;
		}
		void drain(std::function<void(T&)> cb) {
			std::lock_guard lck(mtx);
			while (this->size() > 0) {
				auto t = std::move(this->front());
				reinterpret_cast<std::queue<T>*>(this)->pop();
				cb(t);
			}
		}
		size_t size() {
			return reinterpret_cast<std::queue<T>*>(this)->size();
		}
	private:
		std::recursive_mutex mtx;
		std::counting_semaphore<maxElements> sem{ 0 };
	};
}