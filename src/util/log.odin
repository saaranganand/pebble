package util

import os "core:os"
import log "core:log"
import fmt "core:fmt"
import time "core:time"
import datetime "core:time/datetime"

LOGGER_PATH :: "log/"
LOGGER_EXT :: ".log"

GLOBAL_LOGGER: log.Logger
USING_GLOBAL_LOGGER: bool
USING_GLOBAL_FILE_LOGGER: bool

allocate_file_logger :: proc(use_file: bool) {
    time_str, ok := time.time_to_rfc3339(time.now(), 0, false)
    if !ok do time_str = ""
    
    log_path := fmt.aprint(LOGGER_PATH, time_str, LOGGER_EXT, sep = "")
    defer delete(log_path)

    defer if ok do delete(time_str)

    USING_GLOBAL_LOGGER = false
    USING_GLOBAL_FILE_LOGGER = false

    os_open_flags := os.O_WRONLY | os.O_CREATE | os.O_TRUNC
    os_mode := os.Permissions{.Read_User, .Write_User, .Read_Group, .Read_Other}

    lowest_level := log.Level.Debug
    when !ODIN_DEBUG do lowest_level = log.Level.Info

    when !ODIN_DEBUG {
        when ODIN_OS == .Linux || ODIN_OS == .Darwin do file, err := os.open(log_path, os_open_flags, os_mode)
        // Windows does not allow for the mode option
        else when ODIN_OS == .Windows do file, err := os.open(log_path, os_open_flags)
        else {
            GLOBAL_LOGGER = log.create_console_logger(lowest_level)
            USING_GLOBAL_LOGGER = true
            return
        }

        if err != os.ERROR_NONE && use_file{
            os.close(file)
            GLOBAL_LOGGER = log.create_console_logger(lowest_level)
            USING_GLOBAL_LOGGER = true
        } else {
            GLOBAL_LOGGER = log.create_file_logger(file, lowest_level)
            USING_GLOBAL_LOGGER = true
            USING_GLOBAL_FILE_LOGGER = true
        }
    } else {
        GLOBAL_LOGGER = log.create_console_logger(lowest_level)
        USING_GLOBAL_LOGGER = true
    }
}

// odins log destruction automatically deallocates the file it handles, if there is one
destroy_file_logger :: proc() {
    if !USING_GLOBAL_LOGGER do return

    log.debug("Destroying logger!")

    if USING_GLOBAL_FILE_LOGGER do log.destroy_file_logger(GLOBAL_LOGGER)
    else do log.destroy_console_logger(GLOBAL_LOGGER)
}