//#define TESTING				//By using the testing("message") proc you can create debug-feedback for people with this
								//uncommented, but not visible in the release version)
//#define DEBUG

//#define DATUMVAR_DEBUGGING_MODE	//Enables the ability to cache datum vars and retrieve later for debugging which vars changed.

// Comment this out if you are debugging problems that might be obscured by custom error handling in world/Error
#ifdef DEBUG
#define USE_CUSTOM_ERROR_HANDLER
#endif

#ifdef TESTING
#define DATUMVAR_DEBUGGING_MODE

///Used to find the sources of harddels, quite laggy, don't be surpised if it freezes your client for a good while
//#define REFERENCE_TRACKING
#ifdef REFERENCE_TRACKING

///Run a lookup on things hard deleting by default.
//#define GC_FAILURE_HARD_LOOKUP
#ifdef GC_FAILURE_HARD_LOOKUP
#define FIND_REF_NO_CHECK_TICK
#endif //ifdef GC_FAILURE_HARD_LOOKUP

#endif //ifdef REFERENCE_TRACKING

#define VISUALIZE_ACTIVE_TURFS	//Highlights atmos active turfs in green
#define TRACK_MAX_SHARE	//Allows max share tracking, for use in the atmos debugging ui
#endif //ifdef TESTING

//#define UNIT_TESTS			//If this is uncommented, we do a single run though of the game setup and tear down process with unit tests in between

/// If this is uncommented, Autowiki will generate edits and shut down the server.
/// Prefer the autowiki build target instead.
// #define AUTOWIKI

#ifndef PRELOAD_RSC				//set to:
#define PRELOAD_RSC	0			//	0 to allow using external resources or on-demand behaviour;
#endif							//	1 to use the default behaviour;
								//	2 for preloading absolutely everything;

#ifdef LOWMEMORYMODE
#define FORCE_MAP "_maps/runtimestation.json"
#endif

//Update this whenever you need to take advantage of more recent byond features
#define MIN_COMPILER_VERSION 514
#define MIN_COMPILER_BUILD 1553
#if DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://secure.byond.com/download and update.
#error You need version 514.1568 or higher
#endif

//Additional code for the above flags.
#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif

// A reasonable number of maximum overlays an object needs
// If you think you need more, rethink it
#define MAX_ATOM_OVERLAYS 100


#if DM_VERSION < 515
#define PROC_REF(X) .proc/##X
#define VERB_REF(X) .verb/##X
#define TYPE_PROC_REF(TYPE, X) ##TYPE.proc/##X
#define TYPE_VERB_REF(TYPE, X) ##TYPE.verb/##X
#define GLOBAL_PROC_REF(X) /proc/##X
#else
/// Call by name proc references, checks if the proc exists on either this type () (AND ONLY THIS TYPE) or as a global proc.
#define PROC_REF(X) (nameof(.proc/##X))
/// Call by name verb references, checks if the verb exists on either this type or as a global verb.
#define VERB_REF(X) (nameof(.verb/##X))
/// Call by name proc reference, checks if the proc exists on either the given type or as a global proc
#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
/// Call by name verb reference, checks if the verb exists on either the given type or as a global verb
#define TYPE_VERB_REF(TYPE, X) (nameof(##TYPE.verb/##X))
/// Call by name proc reference, checks if the proc is an existing global proc
#define GLOBAL_PROC_REF(X) (/proc/##X)
#endif
