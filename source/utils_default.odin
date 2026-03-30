#+build !wasm32
#+build !wasm64p32

package game

import "core:os"

_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> ([]byte, bool) {
    data, err := os.read_entire_file(name, allocator, loc)
    if err != nil {
        return nil, false
    }
    return data, true
}

_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return os.write_entire_file(name, data, truncate = true) == nil
}
