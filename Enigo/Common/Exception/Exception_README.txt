perllib/Enigo/Common/Exception

    This is the home of the various Enigo::Common::Exception subclasses.  These
    classes ultimately descend from Error.pm, and provide specific types of
    errors in a hierarchial manner to allow for sophisticated OO type error
    handling with a flavor very similar to Java's (and C++'s) scheme of
    try/throw/catch error handling.

    The exceptions are arranged into hierarchies that get more detailed as
    one descends.  So, a file not found error, being a file IO error, is
    found under Enigo::Common::Exception::IO::File::FileNotFound.  All File
    errors are found under Enigo::Common::Exception::IO::File.  A syntax error
    with an eval would call for the use of Enigo::Common::Exception::Eval. 
    Etc...

