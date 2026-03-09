#include "platform.h"

#include <sstream>

#ifdef __ANDROID__
#include <sys/prctl.h>
#endif

std::string GetCurrentThreadID() {

    auto myid = std::this_thread::get_id();
    std::stringstream ss;
    ss << myid;
    return ss.str();
}

void SetCurrentThreadName(const std::string& name) {

#ifdef ANDROID_PLATFORM
    // 16 byte limit for the thread name, including null terminator.
    prctl(PR_SET_NAME, (unsigned long)name.substr(0, 15).c_str(), 0, 0, 0);
#else

    name;
#endif
}

#if defined(ANDROID_PLATFORM)

#if defined(ANDROID_GNU_STL)

namespace std {

#if !defined(_GLIBCXX_USE_C99_MATH_TR1)

    float round(float arg) { return ::round(arg); }
    double round(double arg) { return ::round(arg); }
    long double round(long double arg) { return ::round(arg); }

#endif

    template<typename t>
    string to_string_t(t value) {

        std::ostringstream ss;
        ss.setf(std::ios::fixed);
        ss.precision(6);
        ss << value;
        return ss.str();
    }

    string to_string(int value) { return to_string_t(value); }
    string to_string(long value) { return to_string_t(value); }
    string to_string(long long value) { return to_string_t(value); }
    string to_string(unsigned value) { return to_string_t(value); }
    string to_string(unsigned long value) { return to_string_t(value); }
    string to_string(unsigned long long value) { return to_string_t(value); }
    string to_string(float value) { return to_string_t(value); }
    string to_string(double value) { return to_string_t(value); }
    string to_string(long double value) { return to_string_t(value); }
}
#endif

#endif

#if defined(_MSC_VER)

// to avoid warning LNK4221
void dummy() {}

#endif

