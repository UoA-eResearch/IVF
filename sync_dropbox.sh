#!/bin/bash
rclone sync -vv dropbox:EmbryoLabeling EmbryoLabeling --exclude '/Labelers/One/{{M\d.+}}/*'
