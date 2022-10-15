package glog

import "core:runtime"

DEBUG :: runtime.Logger_Level.Debug
INFO :: runtime.Logger_Level.Info
WARNING :: runtime.Logger_Level.Warning
ERROR :: runtime.Logger_Level.Error
FATAL :: runtime.Logger_Level.Fatal

// bigger number is more urgent
DEBUG0 :: DEBUG
DEBUG1 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG0) + 1 >= uint(INFO) else uint(DEBUG0) + 1)
DEBUG2 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG1) + 1 >= uint(INFO) else uint(DEBUG1) + 1)
DEBUG3 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG2) + 1 >= uint(INFO) else uint(DEBUG2) + 1)
DEBUG4 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG3) + 1 >= uint(INFO) else uint(DEBUG3) + 1)
DEBUG5 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG4) + 1 >= uint(INFO) else uint(DEBUG4) + 1)
DEBUG6 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG5) + 1 >= uint(INFO) else uint(DEBUG5) + 1)
DEBUG7 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG6) + 1 >= uint(INFO) else uint(DEBUG6) + 1)
DEBUG8 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG7) + 1 >= uint(INFO) else uint(DEBUG7) + 1)
DEBUG9 :: runtime.Logger_Level(uint(INFO) - 1 when uint(DEBUG8) + 1 >= uint(INFO) else uint(DEBUG8) + 1)
