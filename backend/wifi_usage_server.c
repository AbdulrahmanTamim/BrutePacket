#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <microhttpd.h>

#define PORT 8888

// Function to fetch Wi-Fi usage data
int get_wifi_usage() {
    // Replace with actual logic to retrieve Wi-Fi usage (example value)
    return 75;  // Example Wi-Fi usage percentage
}

// Callback function to handle HTTP requests
static int answer_to_request(void *cls, struct MHD_Connection *connection,
                              const char *url, const char *method,
                              const char *version, const char *upload_data,
                              size_t *upload_data_size, void **con_cls) {
    if (strcmp(url, "/api/wifi-usage") == 0) {
        // Fetch Wi-Fi usage data
        int wifi_usage = get_wifi_usage();
        
        // Respond with the JSON data
        char response[256];
        snprintf(response, sizeof(response), "{\"usage\": %d}", wifi_usage);
        
        struct MHD_Response *response_obj = MHD_create_response_from_buffer(strlen(response), (void *)response, MHD_RESPMEM_PERSISTENT);
        MHD_add_response_header(response_obj, "Content-Type", "application/json");
        
        // Send the response
        int ret = MHD_queue_response(connection, MHD_HTTP_OK, response_obj);
        MHD_destroy_response(response_obj);
        return ret;
    }
    
    return MHD_NO;
}

int main() {
    struct MHD_Daemon *daemon;
    
    // Start the HTTP server
    daemon = MHD_start_daemon(MHD_USE_SELECT_INTERNALLY, PORT, NULL, NULL,
                              &answer_to_request, NULL, MHD_OPTION_END);
    if (NULL == daemon) {
        fprintf(stderr, "Error starting the server\n");
        return 1;
    }
    
    printf("Server is running on http://localhost:%d\n", PORT);
    
    // Run the server indefinitely
    getchar();
    
    MHD_stop_daemon(daemon);
    
    return 0;
}
