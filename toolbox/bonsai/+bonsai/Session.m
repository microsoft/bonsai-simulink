% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Simulator session base class for the Bonsai toolbox

classdef Session < handle

    properties (Constant, Access = private)
        objectInstance = bonsai.Session;
    end

    properties
        config BonsaiConfiguration
        sessionId char
        isTrainingSession logical
        lastSequenceId double
        lastEvent bonsai.EventTypes
        lastAction struct
        episodeConfig struct
        model char;
        episodeStartCallback function_handle;
    end

    properties (Access = private)
        client bonsai.Client
        logger bonsai.Logger
        csvWriter bonsai.CSVWriter
        episodeCount double
    end

    methods (Static)
        function retObj = getInstance
            % returns singleton 
            retObj = bonsai.Session.objectInstance;
        end
        
        function retObj = loadobj(~)
            % ignore the input and instead return the singleton
            retObj = bonsai.Session.objectInstance;
        end
    end

    methods (Access = private)
        function obj = MySingleton
            obj.counter = 0;
        end

        function resetSessionProperties(obj)
            obj.sessionId = '';
            obj.lastSequenceId = 1;
            obj.lastEvent = bonsai.EventTypes.Idle;
            obj.lastAction = struct();
            obj.episodeConfig = struct();
        end
    end

    methods

        function configure(obj, config, mdl, episodeStartCallback, isTrainingSession)

            % initialize logger
            obj.logger = bonsai.Logger('Session', config.verbose);

            % display version of toolbox being used
            addons = matlab.addons.installedAddons;
            addonLookup = contains(addons.Name, 'Bonsai');
            if any(addonLookup)
                toolboxVersion = addons{addonLookup, {'Version'}};
                obj.logger.log(strcat('Bonsai MATLAB Toolbox Version: ', toolboxVersion));
            else
                obj.logger.log('Bonsai MATLAB Toolbox Version: Dev/Local');
            end

            % validate configuration
            config.validate();

            % if state or action schemas missing, attempt to use port data
            if isempty(config.stateSchema) || isempty(config.actionSchema)
                try
                    obj.logger.verboseLog('Attempting to get state and action schemas from Bonsai block ports...');
                    portData = bonsai.GetPortData(config.bonsaiBlock);
                    obj.logger.verboseLog('Port data from Bonsai block found:');
                    obj.logger.verboseLog(portData);
                    
                    if isempty(config.stateSchema)
                        config.stateSchema = portData.stateSchema;
                    end
                    if isempty(config.actionSchema)
                        config.actionSchema = portData.actionSchema;
                    end

                    % % TODO: use types from portData when there is support for more than just doubles
                    % if isempty(config.stateType)
                    %     config.stateType = portData.stateType;
                    % end
                    % if isempty(config.actionType)
                    %     config.actionType = portData.actionType;
                    % end

                catch ME
                    disp(['Unable to get state and action data from block "', config.bonsaiBlock, '".']);
                    disp(['ID: ' ME.identifier]);
                    rethrow(ME);
                end
            end

            % set session properties
            obj.config = config;
            obj.model = char(mdl);
            obj.episodeStartCallback = episodeStartCallback;
            obj.isTrainingSession = isTrainingSession;
            obj.client = bonsai.Client(config);
            obj.resetSessionProperties();
        end

        function startNewSession(obj)

            % reset session
            obj.resetSessionProperties();

            % initialize CSV Writer if enabled
            if obj.config.csvWriterEnabled()
                obj.logger.verboseLog('CSV Writer enabled');
                obj.csvWriter = bonsai.CSVWriter(obj.config);
            else
                obj.logger.verboseLog('CSV Writer disabled');
            end

            % register sim and reset episode count
            r = obj.client.registerSimulator(obj.config.registrationJson());
            obj.episodeCount = 0;

            % confirm registration successful
            if isempty(r.sessionId)
                error('There was a problem with sim registration');
            else
                obj.logger.log('Sim successfully registered');
            end

            % update session data
            obj.sessionId = r.sessionId;
            obj.lastEvent = bonsai.EventTypes.Registered;
        end

        function keepGoing = startNewEpisode(obj)
            fprintf(1, newline);
            keepGoing = true;

            if ~eq(obj.lastEvent, bonsai.EventTypes.EpisodeStart) && ...
                ~eq(obj.lastEvent, bonsai.EventTypes.Unregister)

                % request events until episodeStart (success) or unregister (failure)
                obj.logger.log('Requesting events until EpisodeStart received...');
                blank_state = zeros(1, obj.config.numStates);
                while ~eq(obj.lastEvent, bonsai.EventTypes.EpisodeStart) && ...
                    ~eq(obj.lastEvent, bonsai.EventTypes.Unregister)

                    % send halted if an episode is still running
                    halted = false;
                    if eq(obj.lastEvent, bonsai.EventTypes.EpisodeStep)
                        halted = true;
                    end

                    obj.getNextEvent(-1, blank_state, halted);
                end
            end

            if eq(obj.lastEvent, bonsai.EventTypes.Unregister)
                keepGoing = false;
            else

                % increment episode count and print appropriate message
                obj.episodeCount = obj.episodeCount + 1;
                fprintf(1, newline);
                if obj.isTrainingSession
                    obj.logger.log(['Starting model ', char(obj.model), ' with episodeStartCallback']);
                else
                    obj.logger.log('Setting episode configuration with episodeStartCallback');
                end

                % call episodeStartCallback to set episode configuration and, if training, run the model
                feval(obj.episodeStartCallback, obj.model, obj.episodeConfig);
                obj.logger.log('Callback complete.');
            end
        end

        function terminateSession(obj)
            % unregister sim
            if strcmp(obj.sessionId, '')
                obj.logger.log('No SessionID found to unregister')
            else
                obj.logger.log(['Unregistering SessionID: ', obj.sessionId]);
                obj.client.deleteSimulator(obj.sessionId);
            end

            % reset session and close csv
            obj.resetSessionProperties();
            if obj.config.csvWriterEnabled()
                obj.csvWriter.close();
            end
        end

        function getNextEvent(obj, time, state, halted)

            % request next event
            simState = containers.Map(obj.config.stateSchema, state);
            requestData = struct('sequenceId', obj.lastSequenceId, ...
                                 'sessionId', obj.sessionId, ...
                                 'halted', halted, ...
                                 'state', simState);
            data = jsonencode(requestData);
            r = obj.client.getNextEvent(obj.sessionId, data);

            % update session data
            obj.sessionId = r.sessionId;
            obj.lastSequenceId = r.sequenceId;
            obj.lastEvent = bonsai.EventTypes(r.type);
            switch r.type
            case bonsai.EventTypes.Registered.str
                error('Unexpected Registration event');
            case bonsai.EventTypes.Idle.str
                if (obj.episodeCount < 1)
                    if obj.isTrainingSession
                        obj.logger.log(['Received event: Idle, please visit https://preview.bons.ai ', ...
                        'and select or create a brain to begin training. Hit "Train" and select ', ...
                        'simulator "', obj.config.name, '" to connect this model.']);
                    else
                        obj.logger.log(['Received event: Idle, please visit https://preview.bons.ai ', ...
                        'to begin assessment on your brain.']);
                    end
                else
                    obj.logger.log('Received event: Idle');
                end
            case bonsai.EventTypes.EpisodeStart.str
                obj.logger.log('Received event: EpisodeStart');
                if isempty(fieldnames(r.episodeStart))
                    % all fields optional, do nothing if nothing received
                else
                    obj.episodeConfig = r.episodeStart.config;
                end
            case bonsai.EventTypes.EpisodeStep.str
                actionString = jsonencode(r.episodeStep.action);
                obj.logger.log(['Received event: EpisodeStep, actions: ', actionString]);
                obj.lastAction = r.episodeStep.action;
            case bonsai.EventTypes.EpisodeFinish.str
                obj.logger.log('Received event: EpisodeFinish');
                % reset action and config
                obj.lastAction = struct();
                obj.episodeConfig = struct();
            case bonsai.EventTypes.Unregister.str
                obj.logger.log('Received event: Unregister');
                % reset action and config
                obj.lastAction = struct();
                obj.episodeConfig = struct();
            otherwise
                error(['Received unknown event type: ', r.type]);
            end

            % write session data to file
            if obj.config.csvWriterEnabled()
                obj.csvWriter.addEntry(time, obj.lastEvent.str, state, halted, obj.lastAction, obj.episodeConfig);
            end
        end

    end
end
