foreach(X RANGE 1 4)
    add_executable(test_base_set${X} test.c)
    target_link_libraries(test_base_set${X} base_set${X})
    target_compile_definitions(test_base_set${X} PUBLIC SET${X})
endforeach()

foreach(X RANGE 1 6)
    add_executable(measure_speed_base_set${X} measure_speed.c)
    target_link_libraries(measure_speed_base_set${X} base_set${X})
    target_compile_definitions(measure_speed_base_set${X} PUBLIC SET${X})
endforeach()

#add_executable(masked_core-test test.c)
#target_link_libraries(masked_core-test masked_core)



