syms x

% --- Safe Function Input ---
while true
    prompt = {'Enter your function in terms of x:'};
    dlgtitle = 'Function Input';
    dims = [1 50];
    answer = inputdlg(prompt, dlgtitle, dims);
    
    if isempty(answer) || isempty(answer{1})
        choice = menu('No function entered. What do you want to do?', 'Retry', 'Exit');
        if choice == 1
            continue;
        else
            disp('Exiting.')
            return
        end
    end
    
    try
        f = str2sym(answer{1});
        break
    catch
        choice = menu('Invalid function syntax. What do you want to do?', 'Retry', 'Exit');
        if choice == 1
            continue;
        else
            disp('Exiting.')
            return
        end
    end
end

originalFunction = f;
derivativeFunction = [];
derivativeOrder = 0;
integralFunction = [];
integralOrder = 0;
limitHistory = [];
definiteIntegralDots = []; % [xmid, yvalue, integralOrder]

while true
    choice = menu('Symbolic Function Tool', ...
        'Plot functions', ...
        'Differentiate', ...
        'Integrate', ...
        'Limit', ...
        'Exit');
    
    switch choice
        case 1
            xRange = linspace(-10, 10, 500);
            originalY = double(subs(originalFunction, x, xRange));
            if ~isempty(derivativeFunction)
                derivativeY = double(subs(derivativeFunction, x, xRange));
            else
                derivativeY = [];
            end
            if ~isempty(integralFunction)
                integralY = double(subs(integralFunction, x, xRange));
            else
                integralY = [];
            end
            
            figure;
            hold on

            % Plot original function
            plot(xRange, originalY, 'k', 'LineWidth', 1.5, 'DisplayName', 'Original f(x)');

            % Plot derivative function
            if ~isempty(derivativeFunction)
                area(xRange, derivativeY, 'FaceColor', 'none', 'EdgeColor', 'blue', 'LineStyle', '--', 'LineWidth', 1.5, ...
                    'DisplayName', ['Derivative Order ', num2str(derivativeOrder)]);
            end

            % Plot integral function
            if ~isempty(integralFunction)
                area(xRange, integralY, 'FaceColor', 'none', 'EdgeColor', 'red', 'LineStyle', '--', 'LineWidth', 1.5, ...
                    'DisplayName', ['Integral Order ', num2str(integralOrder)]);
            end

            % Plot limit points
            for i = 1:size(limitHistory, 1)
                plot(double(limitHistory(i, 1)), double(limitHistory(i, 2)), 'ro', ...
                    'MarkerSize', 8, 'DisplayName', ['Limit ' num2str(i)]);
            end

            % Plot definite integral points (max 3, show value in label)
            for i = 1:size(definiteIntegralDots, 1)
                plot(double(definiteIntegralDots(i, 1)), double(definiteIntegralDots(i, 2)), 'ro', ...
                    'MarkerSize', 8, ...
                    'DisplayName', ['∫^', num2str(definiteIntegralDots(i,3)) 'f(x)dx = ', num2str(definiteIntegralDots(i,2))]);
            end

            % Smart Y-axis scaling
            yAll = originalY;
            if ~isempty(derivativeY)
                yAll = [yAll, derivativeY];
            end
            if ~isempty(integralY)
                yAll = [yAll, integralY];
            end
            if ~isempty(limitHistory)
                yAll = [yAll, limitHistory(:,2)'];
            end
            if ~isempty(definiteIntegralDots)
                yAll = [yAll, definiteIntegralDots(:,2)'];
            end

            ymin = min(yAll);
            ymax = max(yAll);
            if ymin == ymax
                ymin = ymin - 1;
                ymax = ymax + 1;
            else
                yPad = (ymax - ymin) * 0.1;
                ymin = ymin - yPad;
                ymax = ymax + yPad;
            end
            ylim([ymin, ymax]);

            grid on
            legend('show')
            hold off

            % Build dynamic title
            titleLines = {['f(x) = ', char(originalFunction)]};
            if ~isempty(derivativeFunction)
                if derivativeOrder == 1
                    titleLines{end+1} = ['f''(x) = ', char(derivativeFunction)];
                elseif derivativeOrder == 2
                    titleLines{end+1} = ['f''''(x) = ', char(derivativeFunction)];
                elseif derivativeOrder == 3
                    titleLines{end+1} = ['f''''''(x) = ', char(derivativeFunction)];
                else
                    titleLines{end+1} = ['f^{' num2str(derivativeOrder) '}(x) = ', char(derivativeFunction)];
                end
            end
            if ~isempty(integralFunction)
                if integralOrder == 1
                    titleLines{end+1} = ['∫f(x)dx = ', char(integralFunction)];
                else
                    titleLines{end+1} = ['∫^' num2str(integralOrder) 'f(x)dx = ', char(integralFunction)];
                end
            end
            title(titleLines, 'Interpreter', 'none')

        case 2
            orderAnswer = inputdlg('Enter order of derivative (e.g., 1 for f'', 2 for f'''', etc.):', ...
                'Derivative Order', [1 50]);
            
            if isempty(orderAnswer) || isempty(orderAnswer{1})
                disp('No order entered.')
            else
                try
                    n = str2double(orderAnswer{1});
                    if isnan(n) || n <= 0 || mod(n,1) ~= 0
                        error('Invalid order');
                    end
                    derivativeOrder = n;
                    derivativeFunction = diff(originalFunction, x, n);
                    disp(['Differentiated order ' num2str(derivativeOrder) ' → ' char(derivativeFunction)])
                catch
                    msgbox('Invalid derivative order.', 'Error', 'error');
                end
            end

        case 3
            intChoice = menu('Choose integration type', 'Primitive (Indefinite)', 'Definite');
            
            if intChoice == 1
                orderAnswer = inputdlg('Enter how many times to integrate (1 = once, 2 = twice, etc.):', ...
                    'Integration Order', [1 50]);
                
                if isempty(orderAnswer) || isempty(orderAnswer{1})
                    disp('No order entered.')
                else
                    try
                        n = str2double(orderAnswer{1});
                        if isnan(n) || n <= 0 || mod(n,1) ~= 0
                            error('Invalid integration order');
                        end
                        integralOrder = n;
                        integralFunction = originalFunction;
                        for k = 1:n
                            integralFunction = int(integralFunction, x);
                        end
                        disp(['Integrated (primitive) order ' num2str(integralOrder) ' → ' char(integralFunction)])
                    catch
                        msgbox('Invalid integration order.', 'Error', 'error');
                    end
                end
                
            elseif intChoice == 2
                definiteIntegralFunction = originalFunction;
                orderAnswer = inputdlg('Enter how many times to integrate (1 = once, 2 = twice, etc.):', ...
                    'Definite Integration Order', [1 50]);
                
                if isempty(orderAnswer) || isempty(orderAnswer{1})
                    disp('No order entered.')
                else
                    try
                        n = str2double(orderAnswer{1});
                        if isnan(n) || n <= 0 || mod(n,1) ~= 0
                            error('Invalid order');
                        end
                        for k = 1:n
                            definiteIntegralFunction = int(definiteIntegralFunction, x);
                            
                            bounds = inputdlg({'Enter lower bound:', 'Enter upper bound:'}, ...
                                ['Bounds for Integral Step ', num2str(k)], [1 50; 1 50]);
                            
                            a = str2double(bounds{1});
                            if isnan(a)
                                a = evalin(symengine, bounds{1});
                            end
                            b = str2double(bounds{2});
                            if isnan(b)
                                b = evalin(symengine, bounds{2});
                            end
                            
                            Fa = subs(definiteIntegralFunction, x, a);
                            Fb = subs(definiteIntegralFunction, x, b);
                            
                            definiteIntegralFunction = Fb - Fa;
                        end
                        
                        finalResult = double(definiteIntegralFunction);
                        disp(['∫^' num2str(n) 'f(x)dx = ', num2str(finalResult)])
                        choiceBack = menu(['∫^', num2str(n), 'f(x)dx = ', num2str(finalResult)], 'Back to Operations');

                        % Save dot
                        mid = (a + b) / 2;
                        if size(definiteIntegralDots,1) >= 3
                            definiteIntegralDots(1,:) = []; % remove oldest
                        end
                        definiteIntegralDots(end+1, :) = [mid, finalResult, n];
                        
                    catch
                        msgbox('Error during definite integration.', 'Error', 'error');
                    end
                end
            end

        case 4
            pointPrompt = {'Enter the value x tends to (e.g., 0, pi, inf):'};
            pointTitle = 'Limit Point Input';
            pointAnswer = inputdlg(pointPrompt, pointTitle, [1 50]);
            if isempty(pointAnswer) || isempty(pointAnswer{1})
                disp('No limit point entered.')
            else
                try
                    numericPoint = str2double(pointAnswer{1});
                    if isnan(numericPoint)
                        numericPoint = evalin(symengine, pointAnswer{1});
                    end
                    L = limit(originalFunction, x, numericPoint);
                    msgbox(['Limit of f(x) as x → ' pointAnswer{1} ' is: ' char(L)], 'Limit Result');
                    limitHistory(end+1, :) = [numericPoint, double(L)];
                    menu('More operations?', 'Continue');
                catch
                    msgbox('Invalid limit input.', 'Error', 'error');
                end
            end

        case 5
            disp('Exiting.')
            break

        otherwise
            disp('Invalid option')
    end
end