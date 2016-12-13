# s3scripts

`s3scripts` is a collection of simple shell scripts which allow the
use of Amazon's AWS S3 service as a file repository. Most of the
scripts provides commands based on various *source control systems*,
though s3scripts doesn't (itself) provide an provisions for version
control or branching and merging. Enabling version control on the
underlying S3 bucket can provide much of the functionality of version
control for individual files.

The basic commands are:

* `s3checkout` *s3path* [*local directory*]:
   This copies the three beneath *s3path* into *local directory* which defaults
   to the basename of *s3path* relative to the current directory.   

* s3update [*local directory*]:
  This updates the contents of *local directory* and it's children from S3. 
  It fails (exiting with status 1 and a message) if *local directory* was not 
  checked out using `s3checkout`.

* s3commit [*local file*...]:
  This saves each *local file* to the corresponding location in the S3 bucket
  from which it's parent directory was checked out.
  

