#!/bin/bash

echo "Resizing disk."

growpart /dev/vda 2
resize2fs /dev/vda2

echo "Done resizing disk."
