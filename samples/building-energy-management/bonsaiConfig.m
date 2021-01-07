% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

function config = bonsaiConfig()
    config = BonsaiConfiguration();

    % % override api url, defaults to "https://api.bons.ai"
    % config.url = "https://api.bons.ai";

    % bonsai workspace
    config.workspace = "<workspace_id>";

    % access key, generated from https://beta.bons.ai/brains/accounts/settings
    config.accessKey = "<key>";

    % simulator name, for an unmanaged simulator launched from the desktop to show up on the web
    config.name = "Simulink BuildingEnergyManagement";

    % path to bonsai block in your model, used to determine state and action schemas
%     config.bonsaiBlock = "Bonsai";

    % % set state and action schemas (overrides data from bonsaiBlock)
    config.stateSchema = ["Tset","Troom","Toutdoor","total_cost"];
    config.actionSchema = ["command"];

    % set config schema
    config.configSchema = ["input_Toutdoor"];

    % % time (in seconds) the simulator gateway should wait for
    % %   your simulator to advance, defaults to 60
    config.timeout = 60;

    % path to csv file where episode data should be logged
    config.outputCSV = "bem-training.csv";

    % % display verbose logs
%     config.verbose = true;
end
