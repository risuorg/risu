## Use of generative AI for plugin creation

You can use a sample text to get a plugin draft created for later review, for example:

```console


I want to create a bash script for checking system status.

The script should use return codes to indicate success, failure, information, error or skipped via the values stored in the variables $RC_OKAY, $RC_SKIPPED, $RC_ERROR, $RC_FAILED and $RC_INFO.

The Path to check for the files in the sosreport are specified in the var $RISU_ROOT when we're running against a sosreport or in the regular system locations when we're running against a live system.

We can know if we're running against a live system by checking the value of the variable RISU_LIVE which is 0 when we're running against a sosreport or 1 when we're running on a live system.

If the script needs to output any relevant information in case of Error, being skipped, etc, it should always write to the standard error instead of the standard output.

The script should check how full is the etcd database in kubernetes
```

Just replace the text for the intended check to perform and review that everything makes sense at the end.
