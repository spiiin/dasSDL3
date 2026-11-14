options gen2
require dassdl3/sdl3_peripherals_boost
require math

struct MotionSensor {
    device : SDL_Sensor?
    id : uint
    timestamp : uint64
    samples : int
    first : float3
    latest : float3
    peak : float
}

var accelerometer : MotionSensor
var gyroscope : MotionSensor
var sample : array<float>

def open_motion_sensor(var sensor : MotionSensor; kind : SDL_SensorType; ids : array<uint>) : bool {
    for (id in ids) {
        if (SDL_GetSensorTypeForID(id) != kind) { continue }
        var opened <- open_sensor(id)
        if (is_err(opened)) {
            print("SDL_OpenSensor: {unwrap_err(opened).message}\n")
            return false
        }
        sensor.device = move_unwrap(opened)
        sensor.id = id
        print("Opened {SDL_GetSensorNameForID(id)}\n")
        return SDL_GetSensorID(sensor.device) == id && SDL_GetSensorType(sensor.device) == kind
    }
    print("Missing motion sensor type {int(kind)}\n")
    return false
}

[export]
def motion_open() : bool {
    var found <- sensors()
    if (is_err(found)) {
        print("SDL_GetSensors: {unwrap_err(found).message}\n")
        return false
    }
    let ids <- move_unwrap(found)
    resize(sample, 3)
    if (!open_motion_sensor(accelerometer, SDL_SensorType.SENSOR_ACCEL, ids)) { return false }
    return open_motion_sensor(gyroscope, SDL_SensorType.SENSOR_GYRO, ids)
}

def record_sample(var sensor : MotionSensor; timestamp : uint64; data : float3; relative : bool) : bool {
    // The bounds reject NaN/Inf and values far beyond a handheld phone's motion.
    if (!(length(data) < 1000.0) || timestamp == 0ul || timestamp < sensor.timestamp) { return false }
    if (sensor.samples == 0) { sensor.first = data }
    sensor.latest = data
    sensor.timestamp = timestamp
    sensor.samples++
    sensor.peak = max(sensor.peak, length(relative ? data - sensor.first : data))
    return true
}

[export]
def motion_event(event : SDL_Event const&) : bool {
    var value : SDL_SensorEvent
    if (!SDL_ReadSensorEvent(event, value)) { return false }
    let data = float3(value.data[0], value.data[1], value.data[2])
    if (value.which == accelerometer.id) {
        return record_sample(accelerometer, value.sensor_timestamp, data, true)
    }
    if (value.which == gyroscope.id) {
        return record_sample(gyroscope, value.sensor_timestamp, data, false)
    }
    return true
}

[export]
def motion_done() : int {
    if (accelerometer.samples < 3 || gyroscope.samples < 3) { return 0 }
    if (accelerometer.peak < 1.0 || gyroscope.peak < 0.5) { return 0 }
    for (device in [accelerometer.device, gyroscope.device]) {
        let result = sensor_data(device, sample)
        if (is_err(result)) {
            print("SDL_GetSensorData: {unwrap_err(result).message}\n")
            return -1
        }
        if (!(length(float3(sample[0], sample[1], sample[2])) < 1000.0)) { return -1 }
    }
    print("Motion sensor events: accel={accelerometer.samples}, gyro={gyroscope.samples}\n")
    print("Motion sensor peaks: accel delta={accelerometer.peak} m/s^2, gyro={gyroscope.peak} rad/s\n")
    return 1
}

[export]
def motion_close() {
    if (gyroscope.device != null) { SDL_CloseSensor(gyroscope.device) }
    if (accelerometer.device != null) { SDL_CloseSensor(accelerometer.device) }
}

[export]
def motion_values(gyro : bool) : float4 {
    let sensor = gyro ? gyroscope : accelerometer
    return float4(sensor.latest.x, sensor.latest.y, sensor.latest.z, sensor.samples > 0 ? 1.0 : 0.0)
}
