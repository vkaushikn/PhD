SS = 7; # number of subsystems
parallel_retailer = [4 5 6 7];
parallel_distributor = [2 3];

subsystem{1}.uloc = [1 2 3];
subsystem{1}.node = 'M'

subsystem{2}.uloc = [4 5 6];
subsystem{2}.node = 'D1';

subsystem{3}.uloc = [7 8 9];
subsystem{3}.node = 'D2';

subsystem{4}.uloc = [10 11];
subsystem{4}.node = 'R1';

subsystem{5}.uloc = [12 13];
subsystem{5}.node = 'R2';

subsystem{6}.uloc = [14 15];
subsystem{6}.node = 'R3';

subsystem{7}.uloc = [16 17];
subsystem{7}.node = 'R4';

save ssdata1 SS parallel_retailer parallel_distributor subsystem
