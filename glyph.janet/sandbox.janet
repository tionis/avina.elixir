(import spork/argparse)

(def version "0.0.0")

(defn make-sandbox-with-allowed
  "create sanboxed env"
  [allowed]
  (def newenv @{})
  (def syms
    (map
      symbol
      (peg/match
        '{:ws (set " \n\r\t")
          :main (any (* (any :ws) '(some (if-not :ws 1))))}
        allowed)))
  (each s syms
    (put newenv s (dyn s)))
  newenv)

(defn make-sandbox "make a new sandbox with default symbols" [] (make-sandbox-with-allowed ````
% %= * *= + ++ += - -- -= -> ->> -?> -?>> / /= < <= = == > >=
abstract? all and apply array array/concat array/ensure array/insert array/new array/peek array/pop
array/push array/remove array/slice array? as-> as?-> band blshift bnot boolean? bor brshift brushift
buffer buffer/bit buffer/bit-clear buffer/bit-set buffer/bit-toggle buffer/blit buffer/clear
buffer/format buffer/new buffer/new-filled buffer/popn buffer/push-byte buffer/push-string
buffer/push-word buffer/slice buffer? bxor bytes? case cfunction? comment comp compile
complement cond coro count dec deep-not= deep= def- default defglobal defmacro defmacro-
defn defn- describe dictionary? distinct doc doc* doc-format
drop drop-until drop-while dyn each empty? env-lookup error eval eval-string even?
every? extreme false? fiber/current fiber/getenv fiber/maxstack fiber/new fiber/setenv fiber/setmaxstack fiber/status
fiber? filter find find-index first flatten flatten-into for freeze frequencies function? generate gensym get get-in hash idempotent?
identity if-let if-not inc indexed? int/s64 int/u64 int? interleave interpose
invert janet/build janet/config-bits janet/version juxt juxt* keep keys keyword
keyword? kvs last length let loop macex macex1 map
mapcat marshal match math/abs math/acos math/asin math/atan math/atan2 math/ceil math/cos math/cosh
math/e math/exp math/floor math/inf math/log math/log10 math/pi math/pow math/random
math/seedrandom math/sin math/sinh math/sqrt math/tan math/tanh max max-order mean
merge merge-into min min-order module/expand-path nat? native neg? next nil? not not= not== number? odd? one? or
order< order<= order> order>= os/arch os/clock os/date os/time os/which pairs parser/byte
parser/clone parser/consume parser/eof parser/error parser/flush parser/has-more
parser/insert parser/new parser/produce parser/state parser/status parser/where partial partition
peg/compile peg/match pos? postwalk prewalk product propagate put put-in range
reduce resume reverse run-context scan-number seq setdyn short-fn some sort
sorted spit string string/ascii-lower string/ascii-upper string/bytes
string/check-set string/find string/find-all string/format string/from-bytes string/has-prefix?
string/has-suffix? string/join string/repeat string/replace string/replace-all string/reverse
string/slice string/split string/trim string/triml string/trimr string? struct struct? sum
symbol symbol? table table/clone table/getproto table/new table/rawget table/setproto
table/to-struct table? take take-until take-while tarray/buffer tarray/copy-bytes
tarray/length tarray/new tarray/properties tarray/slice tarray/swap-bytes trace true? try
tuple tuple/brackets tuple/setmap tuple/slice tuple/sourcemap tuple/type tuple? type unless
unmarshal untrace update update-in values varglobal walk when when-let with with-dyns
with-syms yield zero? zipcoll````))

(defn eval-code-in-sandbox
  "eval code in give sandbox"
  [code sandbox]
  (defn sandbox-wrap []
    (string/format "%.10q" (eval-string code)))
  (def f (fiber/new sandbox-wrap :a))
    (fiber/setenv f sandbox)
    (def res (resume f))
    (def sig (fiber/status f))
    (if (= sig :dead)
      res
      (string "signal " sig " raised: " res)))

(defn sandbox-eval "eval code in new default sandbox" [code] (eval-code-in-sandbox code (make-sandbox)))
