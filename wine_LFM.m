clc; clear; close all; format compact; 

fid = fopen('WINE.TXT');    
junk = fgetl(fid);
junk = fscanf(fid,'%s',1);
nin = fscanf(fid,'%d',1); %nin = number of inputs ,πλήθος των εισόδων 
junk = fscanf(fid,'%s',1);
nout = fscanf(fid,'%d',1); %nout = πλήθος των εξόδων (3 κατηγορίες κρασιών) 
junk = fscanf(fid,'%s',1);
nrpat = fscanf(fid,'%d',1); %nrpat = πλήθος των δεδομένων 

A = fscanf(fid,'%f',[nin+nout,Inf]); %A = [I/O pairs]
fclose(fid);

x = A(1:nin,:); % πίνακας εισόδων ( 13 γραμμές * 178 στήλες )
d = A(nin+1:nin+nout,:); % Οι επιθυμιτές εξόδοι (3 γραμμές * 178 στήλες)
                         
trpats=124; % εκπαιδειτικό σύνολο
valpats=36;  % σύνολο τεκμηρίωσης
testpats=18; % σύνολο ελέγχου 

%Εισαγωγή απο το πληκτρολόγιο,ppc:νευρώνια ανά κατηγορία , epochs:εποχές ,
%ka:ρυθμίζει πόσο γρήγορα θα τείνει το α(t) στο μηδέν.
ppc=input ('Δώσε το ppc[1,2,5]: ') ;   
epochs=input ('Δώσε τις epochs[5,10,15]: ') ; 
ka=input ('Δώσε το ka[0.01,0.1]:  ') ;  

tic % Αρχή χρονομέτρησης
            %Tυχαία μετάθεση των στηλων των πινακων x και d 
            for ii=1:10 
                % idx: οι καινούριοι δείκτες (διάνυσμα με μήκος 178)
                idx=randperm(nrpat);
                d=d(:,idx);
                nn=ppc*nout; % Συνολικό πλήθος νευρωνείων
                x=x(:,idx); 
                W=zeros(nin,nn); % Πινακας βαρών  
                L=[]; % Πινακας των κατηγοριών(ετικετών) που ανήκει τα νευρώνια
                      
                for i=1:ppc
                    L=[L,[1:3]]; % συνενωση απο δεξία (3 κατηγορίες)
                end

                % Προετοιμασία πινάκων για τα αποτελέσματα σε κάθε
                % cross-validation loop και ανά εποχή
                cvtr=zeros(epochs,10); % Για το εκπαιδευτικό σύνολο  
                cvval=zeros(epochs,10); % Για το συνολο τεκμηριωσης
                cvtst=zeros(epochs,10); % Για το σύνολο ελέγχου

                for i=1:10 % Για κάθε κύκλο του cross-validation  
                    idxtr=mod((i-1)*testpats:(i-1)*testpats+trpats-1,nrpat)+1; % Δείκτες του εκπαιδευτικού συνόλου 
                    Ptr=x(:,idxtr); % Πίνακας εισόδων για το εκπαιδευτικό σύνολο                                  
                    dtr=d(:,idxtr); % Επιθυμητές εξόδοι για το εκπαιδευτικό σύνολο

                    idxval=mod((i-1)*testpats+trpats:((i-1)*testpats+trpats)+valpats-1,nrpat)+1;% Δείκτες του συνόλου τεκμηρίωσης
                    Pval=x(:,idxval);% Πίνακας εισόδων για το σύνολο τεκμηρίωσης
                    dval=d(:,idxval);% Επιθυμητές εξόδοι για το σύνολο τεκμηρίωσης

                    idxtest=mod(((i-1)*testpats+trpats)+valpats:(((i-1)*testpats+trpats)+valpats)+testpats-1,nrpat)+1;% Δείκτες του συνόλου ελέγχου
                    Ptest=x(:,idxtest);% Πίνακας εισόδων για το σύνολο ελέγχου
                    dtest=d(:,idxtest);% Επιθυμητές εξόδοι για το σύνολο ελέγχου

                    % Μεταροπή των πινάκων εξόδων του κάθε συνόλου.
                    trlabels=vec2ind(dtr);  
                    vallabels=vec2ind(dval);
                    testlabels=vec2ind(dtest);


                     k=1;
                    for c=1:nn % Αρχικοποίηση των προτύπων διανυσμάτων με βάση το εκπαιδευτικό σύνολο
                        while (trlabels(k)~=L(c)) 
                              k=k+1;
                        end
                        W(:,c)=Ptr(:,k); % Ενημέρωση του πίνακα βαρών
                    end

                
                     for ep=1:epochs % Για κάθε εποχή 
                        for iter=1:trpats % Για κάθε στοιχείο του εκπαιδευτικού συνόλου
                            a0=0.5;
                            s=0.6;
                            t=(ep-1)*trpats+iter-1;
                            a=a0/(1+ka*t); % Προσαρμοστικό κέρδος
                            ed=vecnorm(W-Ptr(:,iter)); %Ευκλείδιες αποστάσεις
                                                         
                            [d1,c1]=min(ed); % Η μικρότερη απόσταση , και σε ποιά θέση βρίσκεται 
                            ed(c1)=1000; % Τοποθέτηση μεγάλου αριθμού στην θέση της μικρότερης απόστασης
                            [d2,c2]=min(ed); % Εύρεση δεύτερης μικρότερης απόστασης και σε ποιά θέση είναι
                            ed(c1)=min(ed); % Επανατοποθέτηση της αρχικής τιμης στην θέση c1


                               % Συνθήκες του αλγόριθμου LFM και ενημέρωση του πίνακα βαρών
                               if (L(c1)~= trlabels(iter))                                   
                                  W(:,c1) = W(:,c1) - a*(Ptr(:,iter) - W(:,c1));
                                  if (L(c2) == trlabels(iter))
                                  W(:,c2) = W(:,c2) + a*(Ptr(:,iter) - W(:,c2));
                                  end
                               end
                        end
                        
                        trcount=0; % Μετρητης για το σύνολο εκπαίδευσης 
                        for a=1:trpats  % Για κάθε στοιχείο του συνόλου εκπαίδευσης
                            ed1=vecnorm(W-Ptr(:,a)); % Υπολόγισε τις αποστάσεις τους απο τον πίνακα βαρών
                            [dist1,c]=min(ed1); % Υπολόγισε την μικρότερη απόσταση 
                            if trlabels(a)==L(c) % Σύγκρινε τα labels
                                trcount=trcount+1; % Αυξησε τον μετρητή 
                            end
                        end
                        cvtr(ep,i)=trcount; % Ενημέρωση του πίνακα cvtr
                        
                        valcount=0; % Μετρητης για το σύνολο τεκμηρίωσης
                        for b=1:valpats  % Για κάθε στοιχείο του συνόλου τεκμιρίωσης
                            ed2=vecnorm(W-Pval(:,b)); % Υπολόγισε τις αποστάσεις τους απο τον πίνακα βαρών
                            [dist2,c]=min(ed2);  % Υπολόγισε την μικρότερη απόσταση
                            if vallabels(b)==L(c)  % Σύγκρινε τα labels
                                valcount=valcount+1; % Αυξησε τον μετρητή
                            end 
                        end
                        cvval(ep,i)=valcount;  % Ενημέρωση του πίνακα cvval
                      
                        testcount=0; % Μετρητης για το σύνολο ελέγχου
                        for j=1:testpats  % Για κάθε στοιχείο του συνόλου ελέγχου
                            ed3=vecnorm(W-Ptest(:,j)); % Υπολόγισε τις αποστάσεις τους απο τον πίνακα βαρών
                            [dist3,c]=min(ed3);  % Υπολόγισε την μικρότερη απόσταση
                            if testlabels(j)==L(c)  % Σύγκρινε τα labels
                                testcount=testcount+1; % Αυξησε τον μετρητή
                            end
                        end
                        cvtst(ep,i)=testcount;  % Ενημέρωση του πίνακα cvtst
                          
                     end
                  end
            end
    M1=mean(cvtr,2); % Μέση τιμή του πίνακα cvtr ανά γραμμή
    M1_rate=(M1/trpats)*100; % Μετατροπή σε ποσοστά
    TR_rate=mean(M1_rate); % Μέση τιμή του πίνακα ποσοστών

    M2=mean(cvval,2); % Μέση τιμή του πίνακα cvval ανά γραμμή
    M2_rate=(M2/valpats)*100;% Μετατροπή σε ποσοστά
    VAL_rate=mean(M2_rate); % Μέση τιμή του πίνακα ποσοστών

    M3=mean(cvtst,2); % Μέση τιμή του πίνακα cvtst ανά γραμμή
    M3_rate=(M3/testpats)*100; % Μετατροπή σε ποσοστά
    TEST_rate=mean(M3_rate); % Μέση τιμή του πίνακα ποσοστών

toc % Τέλος χρονομέτρησης 


