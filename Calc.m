syms x
e = exp(sym(1));

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
        f = subs(f, sym('e'), e);
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
limitDots = [];
definiteIntegralDots = [];

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

            plot(xRange, originalY, 'k', 'LineWidth', 1.5, 'DisplayName', 'Original f(x)');

            if ~isempty(derivativeFunction)
                area(xRange, derivativeY, 'FaceColor', 'none', 'EdgeColor', 'blue', 'LineStyle', '--', 'LineWidth', 1.5, ...
                    'DisplayName', ['Derivative Order ', num2str(derivativeOrder)]);
            end

            if ~isempty(integralFunction)
                area(xRange, integralY, 'FaceColor', 'none', 'EdgeColor', 'red', 'LineStyle', '--', 'LineWidth', 1.5, ...
                    'DisplayName', ['Integral Order ', num2str(integralOrder)]);
            end

            for i = 1:size(limitDots, 1)
                label = sprintf('limit x -> %s of f(x) = %.6g', char(sym(limitDots(i,1))), limitDots(i,2));
                plot(limitDots(i,1), limitDots(i,2), 'bo', 'MarkerSize', 8, 'DisplayName', label);
            end

            for i = 1:size(definiteIntegralDots, 1)
                plot(definiteIntegralDots(i,1), definiteIntegralDots(i,2), 'ro', ...
                    'MarkerSize', 8, ...
                    'DisplayName', ['∫^', num2str(definiteIntegralDots(i,3)) 'f(x)dx = ', num2str(definiteIntegralDots(i,2))]);
            end

            yAll = originalY;
            if ~isempty(derivativeY)
                yAll = [yAll, derivativeY];
            end
            if ~isempty(integralY)
                yAll = [yAll, integralY];
            end
            if ~isempty(limitDots)
                yAll = [yAll, limitDots(:,2)'];
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
            orderAnswer = inputdlg('Enter order of derivative:', 'Derivative Order', [1 50]);
            if isempty(orderAnswer), continue; end
            n = str2double(orderAnswer{1});
            if isnan(n) || n <= 0 || mod(n,1) ~= 0
                msgbox('Invalid order', 'Error', 'error'); continue;
            end
            derivativeOrder = n;
            derivativeFunction = diff(originalFunction, x, n);

        case 3
            intChoice = menu('Choose integration type', 'Indefinite', 'Definite');
            if intChoice == 1
                orderAnswer = inputdlg('How many times to integrate:', 'Order', [1 50]);
                if isempty(orderAnswer), continue; end
                n = str2double(orderAnswer{1});
                if isnan(n) || n <= 0 || mod(n,1) ~= 0
                    msgbox('Invalid order', 'Error', 'error'); continue;
                end
                integralOrder = n;
                integralFunction = originalFunction;
                for k = 1:n
                    integralFunction = int(integralFunction, x);
                end
            else
                orderAnswer = inputdlg('How many times to integrate:', 'Order', [1 50]);
                if isempty(orderAnswer), continue; end
                n = str2double(orderAnswer{1});
                if isnan(n) || n <= 0 || mod(n,1) ~= 0
                    msgbox('Invalid order', 'Error', 'error'); continue;
                end
                F = originalFunction;
                for k = 1:n
                    F = int(F, x);
                    bounds = inputdlg({'Lower bound:', 'Upper bound:'}, ...
                        ['Bounds for Integral Step ', num2str(k)], [1 50; 1 50]);
                    a = str2double(bounds{1});
                    b = str2double(bounds{2});
                    if isnan(a), a = evalin(symengine, bounds{1}); end
                    if isnan(b), b = evalin(symengine, bounds{2}); end
                    F = subs(F, x, b) - subs(F, x, a);
                end
                val = double(F);
                msg = ['∫^' num2str(n) 'f(x)dx = ' num2str(val)];
                menu(msg, 'Back to Operations');
                mid = (a + b)/2;
                if size(definiteIntegralDots,1) >= 3
                    definiteIntegralDots(1,:) = [];
                end
                definiteIntegralDots(end+1,:) = [mid, val, n];
            end

        case 4
            pointAnswer = inputdlg('Enter value x → a:', 'Limit Point', [1 50]);
            if isempty(pointAnswer), continue; end
            try
                a = str2double(pointAnswer{1});
                if isnan(a), a = evalin(symengine, pointAnswer{1}); end
                L = limit(originalFunction, x, a);
                val = double(L);
                label = sprintf('limit x -> %s of f(x) = %.6g', char(sym(a)), val);
                menu(label, 'Back to Operations');
                if size(limitDots,1) >= 3
                    limitDots(1,:) = [];
                end
                limitDots(end+1,:) = [a, val, string(label)];
            catch
                msgbox('Invalid limit', 'Error', 'error');
            end

        case 5
            disp('Exiting.'); break
    end
end