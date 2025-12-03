extends Node

var user_id = "user-cuid-from-nextjs"  # Pass this from your Next.js app
var api_base_url = "https://your-nextjs-app.com/api"

func fetch_user_images():
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(self._on_request_completed)
    
    var url = api_base_url + "/users/" + user_id + "/images"
    var error = http_request.request(url)
    
    if error != OK:
        push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
    if result == HTTPRequest.RESULT_SUCCESS:
        if response_code == 200:
            var json = JSON.new()
            json.parse(body.get_string_from_utf8())
            var response = json.get_data()
            
            if response and response.has("images"):
                for image_data in response["images"]:
                    # Download and display the image
                    download_image(image_data["url"], image_data["id"])
        else:
            print("Error: ", response_code)
    else:
        print("HTTP request failed")

func download_image(image_url: String, image_id: String):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(self._on_image_downloaded.bind(image_id))
    
    var error = http_request.request(image_url)
    if error != OK:
        push_error("Error requesting image download")

func _on_image_downloaded(result, response_code, headers, body, image_id):
    if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
        var image = Image.new()
        var image_texture = ImageTexture.new()
        
        # Load image based on format (you might need to handle different formats)
        if image.load_jpg_from_buffer(body) == OK:
            image_texture.create_from_image(image)
        elif image.load_png_from_buffer(body) == OK:
            image_texture.create_from_image(image)
        else:
            push_error("Failed to load image")
            return
        
        # Store or use the texture in your game
        GameState.user_images[image_id] = image_texture
        print("Image loaded successfully: ", image_id)
