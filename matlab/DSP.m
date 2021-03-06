classdef DSP
    % Class DSP
    % Meant as a library for digital signal processing
    methods (Static)
        function yk = real_filter(B,A,k,x,y)
            Na = length(A);
            Nb = length(B);
            xx = x(k:-1:(k-Nb+1));
            yy = y(k:-1:(k-Na+2));
            yk = (dot(xx,B) - dot(yy,A(2:end)))/A(1);
        end
        function [t_mean,t_std] = t_dispersion(t)
            d_t = diff(t);
            t_mean = mean(d_t);
            t_std  = std(d_t);
            histfit(d_t)
        end
        function d = get_damping(T,t,x)
            % d = get_damping(T,t,x)
            tau = DSP.fit_exp(t,x);
            [X,f]   = DSP.get_fft(T,x);
            f_damped = DSP.damped_f(X,f,1);      %% HARCODED f_min = 1Hz;
            [d,~] = DSP.damping(f_damped,tau);
        end
        function [tau,k] = fit_exp(t,x)
            % [tau,k] = fit_exp(t,x)
            % x(t) = k*exp(-t/tau);
            % k [Float]
            % tau [Float]
            model = fit(t,DSP.envelope(x), 'exp1');
            k = model.a;
            tau = -1/model.b;
        end
        function env = envelope(x)
            env = abs(hilbert(x));
        end
        function f_damped = damped_f(X,f,f_dc)
            % f_damped = natural_freq(T,x)
            % X [N x 1][Complex]: FFT of the signal x
            % f [N x 1][Float]: frequencies for X
            % f_dc [Float]: Cut off value to ignore DC components
            aX = abs(X(f>f_dc));
            af = f(f>f_dc);
            [~,index] = max(aX);
            f_damped = af(index);
        end
        function [X,f] = get_fft(T,x)
            % [X,f] = get_fft(t,x)
            % Finds the fourier transform of x (assumes sampled at T)
            % FFT is more efficient when the number of samples (N) in the
            % signal is a power of 2
            N = length(x);
            NFFT = 2^nextpow2(N);
            X = fft(x,NFFT);
            X = X(1:NFFT/2+1);
            f = 1/2/T*linspace(0,1,NFFT/2+1)'; % Reaches up to Nyquist freq
        end
        function [d, f_natural] = damping(f_damped,tau_fit)
            % d = damping(f_damped,tau_fit)
            % Calculates the damping coefficient from:
            % f_damped [Float]: frequency from FFT
            % taut_fit [Float]: decay from fitted exponential
            d = 1/(tau_fit*(2*pi*f_damped));
            f_natural = 1/(tau_fit*d*2*pi);   %% REVISE
        end
        function r = nm_rms(x)
            % r = nm_rms(x)
            % Normalizes the rms with respect to the maximum amplitude
            % squared
            r = rms(x)/(max(abs(x))^2);
        end
        function phi = phase(x,y)
            % phi = phase(x,y) [Degrees]
            % Naive implementation of phase between signals.
            phi = (180/pi)*dot(x,y)/(norm(x)*norm(y));
        end
        %% PLOT METHODS
        function plot_exp(T,t,x)
            %% Get Fit
            [tau,k] = DSP.fit_exp(t,x);
            [X,f]   = DSP.get_fft(T,x);
            f_damped = DSP.damped_f(X,f,1);      %% HARCODED f_min = 1Hz;
            [damping,f_natural] = DSP.damping(f_damped,tau);
            %% Plot Fitted function
            message = { DSP.to_str('\tau',tau,'s'),
                DSP.to_str('f',f_natural,'Hz'),
                DSP.to_str('\zeta',damping,'')};
            figure
            hold on
            title('Signal with Exponential Envelope');
            grid on
            plot(t,x-mean(x))
            plot(t,k*exp(-t/tau),'k')
            plot(t,-k*exp(-t/tau),'k')
            legend('Meassured Signal','K*e^{-t/\tau}');
            text(0.8*t(end),0.5*max(x),message)
            hold off
        end
        function s = to_str(var_sym,value,units)
            s = [var_sym, ' = ', num2str(value), units];
        end
        function plot_spectrum(T,x)
            % Plot single-sided amplitude spectrum.
            [X,f]   = DSP.get_fft(T,x);
            f_damped = DSP.damped_f(X,f,1);
            message = [num2str(f_damped),'Hz'];
            aX = abs(X);
            figure;
            hax = axes;
            hold on
            plot(f,aX,'k')
            title('Single-Sided Amplitude Spectrum of a_z(t)')
            % line([f_damped f_damped],get(hax,'YLim'));
            text(1.5*f_damped,0.5*max(aX),message)
            xlabel('Frequency (Hz)')
            ylabel('|Y(f)|')
            hold off
        end
    end
end