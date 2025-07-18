cimport urh.dev.native.lib.chydrasdr as chydrasdr
import time
from cpython cimport array
import array
# noinspection PyUnresolvedReferences
from cython.view cimport array as cvarray  # needed for converting of malloc array to python array
from urh.util.Logger import logger


ctypedef unsigned char uint8_t
ctypedef unsigned int uint32_t
ctypedef unsigned long long uint64_t

cdef chydrasdr.hydrasdr_device* _c_device
cdef object f

cdef int _c_callback_recv(chydrasdr.hydrasdr_transfer*transfer) noexcept with gil:
    global f
    try:
        (<object> f)(<float [:2*transfer.sample_count]>transfer.samples)
    except OSError as e:
        logger.warning("Cython-HydraSDR:" + str(e))
    return 0

cpdef open_by_serial(uint64_t serial_number):
    return chydrasdr.hydrasdr_open_sn(&_c_device, serial_number)

cpdef open():
    return chydrasdr.hydrasdr_open(&_c_device)

cpdef close():
    return chydrasdr.hydrasdr_close(_c_device)

cpdef array.array get_sample_rates():
    cdef uint32_t count = 0
    result = chydrasdr.hydrasdr_get_samplerates(_c_device, &count, 0)
    if result != chydrasdr.hydrasdr_error.HYDRASDR_SUCCESS:
        return array.array('I', [])

    cdef array.array sample_rates = array.array('I', [0]*count)
    result = chydrasdr.hydrasdr_get_samplerates(_c_device, &sample_rates.data.as_uints[0], count)

    if result == chydrasdr.hydrasdr_error.HYDRASDR_SUCCESS:
        return sample_rates
    else:
        return array.array('I', [])

cpdef int set_sample_rate(uint32_t sample_rate):
    """
    Parameter samplerate can be either the index of a samplerate or directly its value in Hz within the list 
    """
    chydrasdr.hydrasdr_set_samplerate(_c_device, sample_rate)

cpdef int set_center_frequency(uint32_t freq_hz):
    """
    Parameter freq_hz shall be between 24000000(24MHz) and 1750000000(1.75GHz)
    """
    return chydrasdr.hydrasdr_set_freq(_c_device, freq_hz)

cpdef int set_baseband_gain(uint8_t lna_gain):
    """
    Shall be between 0 and 15
    """
    return chydrasdr.hydrasdr_set_lna_gain(_c_device, lna_gain)

cpdef int set_rf_gain(uint8_t mixer_gain):
    """
    Shall be between 0 and 15
    """
    return chydrasdr.hydrasdr_set_mixer_gain(_c_device, mixer_gain)

cpdef int set_if_rx_gain(uint8_t vga_gain):
    """
    Shall be between 0 and 15
    """
    return chydrasdr.hydrasdr_set_vga_gain(_c_device, vga_gain)

cpdef int start_rx(callback):
    global f
    f = callback
    chydrasdr.hydrasdr_set_sample_type(_c_device, chydrasdr.hydrasdr_sample_type.HYDRASDR_SAMPLE_FLOAT32_IQ)
    return chydrasdr.hydrasdr_start_rx(_c_device, _c_callback_recv, NULL)

cpdef int stop_rx():
    time.sleep(0.01)
    return chydrasdr.hydrasdr_stop_rx(_c_device)

cpdef str error_name(chydrasdr.hydrasdr_error error_code):
    cdef const char* c_error_name = chydrasdr.hydrasdr_error_name(error_code)
    return c_error_name.decode('UTF-8')
