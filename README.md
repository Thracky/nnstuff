# Thracky's 'safe' backfill script

* This script is for those of us who don't have the hardware to run update_releases in a separate process while backfilling, or don't want to risk a huge postprocessing backlog.

* The script will incrementally backfill one day at a time, ensuring that all releases are processed for each day of backfill.

* update_binaries will be run every 'x' runs of update_releases in order to keep your current releases up to date while backfilling. This value is set in BINARIES_KEEPUP.

* It will also run update_parsing, removespecial, update_cleanup, and optimise_db after each day of backfill is completed.



## Usage

* First edit the paths for PHP and Newznab, set the number of days to backfill, enter your MySQL information, and number of update_releases loops to allow before running update_binaries again.

* Then simply run the script.

**This script is intended to be run instead of your usual screen script until you've reached the desired level of backfill**

## FAQ

* **Do I need to set my backfill days for groups in the site admin?**
   No, the script will do it for you, and you may overload the backfilling process if you set it manually.


* **Should I run this at the same time as my screen script?**
   No, as mentioned above, this is meant to temporarily replace your screen script until you're done backfilling.


* **Does the script stop when it's done backfilling?**
   Nope, it will keep running so you don't fall behind on current releases until you notice your backfilling is finished and switch back to your regular screen script.


* **How do I know when the script is done?**
   You'll need to keep an eye on your active groups in Admin/View Groups to see what the "Backfill Days" value is.  Once they're at the number of days you set in BACKFILL_DAYS, you're done!
   
   
