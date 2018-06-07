# Create and upload new image crops

The assets are organized in 3 folders on the P drive at `P/Othmer Library/Digital Collections - External Access/Crops for Hydra Redesign/`

First download the original tiff into `uncropped_originals/`. Use the `base_name` provided on the spreadsheet: https://docs.google.com/spreadsheets/d/1D4HFGb0Yy4iFDiRrbw9LKN51Dld8YAXklLAbAp0ZRTM/edit#gid=0

- Open the tiff in your image software.
- If you're making a thumbnail for a collection or a featured topic, crop the image to a 700 pixel square. (This is actually double resolution we display at, for high-res screens).
- Regardless, crop such that height and width are equal or just eyeball the proportions for a hero image / featured collection image.
- Save into the directory `cropped_tiffs`; optionally into the `categories` or `collections` subdirectory.
- Add `_full` onto the filename.

Developer instructions for associating a cropped image with a collection:

- At the command line, cd into the `Crops for Hydra Redesign` directory. (On a Mac, if you've installed the ignyte software, you'll find the shared drive in `/Volumes/315chestnut`). Use ImageMagick to resize the image with the quality settings recommended by google:
`convert cropped_tiffs/[BASE_NAME]_full.tif -resize [WIDTH]x -quality 85 -interlace JPEG -colorspace RGB web_ready/[BASE_NAME]_2x.jpg`

- Copy the resulting image into the code repository at the desired location under `app/assets/images/`. Create a new branch, commit this change, push the branch, and create a pull request.

- If you've added a collection image, once the new image has been deployed a rake task needs to be run to link the image to the collection itself. For documentation of that task, including an example, run `RAILS_ENV=production bundle exec rake -D collection`

- For more background see https://github.com/chemheritage/chf-sufia/issues/529
