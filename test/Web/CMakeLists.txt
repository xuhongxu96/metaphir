add_metaphir_test(metaphir-web-test WebQueryTest.cpp)
add_metaphir_test(metaphir-web-index-test WebIndexTest.cpp)
add_metaphir_test(metaphir-web-publish-test WebPublisherTest.cpp)

target_link_libraries(metaphir-web-test PRIVATE metaphir-web-publish
                                                LLVMAsmParser)

target_link_libraries(metaphir-web-index-test PRIVATE metaphir-web-publish)
target_link_libraries(metaphir-web-publish-test PRIVATE metaphir-web-publish)
