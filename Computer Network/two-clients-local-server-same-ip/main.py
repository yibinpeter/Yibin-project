# Create directory
import os.path

# dirName = 'tempDir'
# try:
#     # Create target Directory
#     os.mkdir(dirName)
#     print("Directory " , dirName ,  " Created ")
# except FileExistsError:
#     print("Directory " , dirName ,  " already exists")



directory = './tempDir'
filename = "file.txt"
file_path = os.path.join(directory, filename)
if not os.path.isdir(directory):
    os.mkdir(directory)
file = open(file_path, "w")
file.write("dsdsadsadasd")
file.close()